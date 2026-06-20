local MSGNAME = "CR.Net.SlotMessage"


-- Net message layout constants
local NETID_BITS = 16
local NETID_MAX = bit.lshift(1, NETID_BITS) - 1

local NET_EPOCH_BITS = 12
local NET_EPOCH_MASK = 4095

local NET_DOMAIN_BITS = 8
local NET_DOMAIN_INITDELETE = 0 --- Id of InitDelete netdomain
local NET_DOMAIN_MAX = 255

--- class CR.Net.Slot
-- A slot capable of holding a networkable object.
-- Manages basically everything about networking of it.
local Slot = CR.Class.Define("CR.Net.Slot")
CR.Class.MakeConstructable(Slot)

CR.Net.Slot = Slot

--- Slot.ObjId: uint
--- Slot.Obj: CR.Net.Networkable|nil
--- Slot.Epoch: uint|nil
--- Slot.Domains: table(domainid: uint, domain: CR.Net.Domain)
--- Slot.DomainInit: nil|CR.Net.DomainInit
--- Slot.Active: bool

-- Stores `Slot`s
Slot.Registry = CR.Registry:New("CR.Net.Slot.Registry")
Slot.Registry.MaxIndex = NETID_MAX

--- Slot:New(obj_id: uint, epoch: uint|nil) -> object(self)
-- Self-registering
function Slot:OnInit(obj_id, epoch)
    Slot.Registry:AddWithId(self, obj_id)

    self:Flush()
    self.ObjId = obj_id
    self.Epoch = epoch
end

function Slot:GetEmpty()
    for _, slot in pairs(self.Registry.Objects) do
        if slot.Obj == nil then
            return slot
        end
    end

    local id = self.Registry:NextIdx()
    return self:New(id, 0)
end

function Slot:__tostring()
    local obj = self.Obj and tostring(self.Obj) or "[unconstructed object]"
    local epoch = self.Epoch and ("epoch "..tostring(self.Epoch)) or "unset epoch"

    return "[slot for "..obj.." w/ id "..tostring(self.ObjId).." at "..epoch"]"
end

--- Delete slot's object if it exists and deletable
function Slot:Flush()
    if CLIENT and IsValid(obj) then 
        if obj.Delete ~= nil then
            obj:Delete()
        else
            ErrorNoHalt("Attempt to flush ",self," with undeletable object.\n",
            "Server is giving wrong commands, pls report to devs. (This won't break anything by itself.)")
        end
    end

    self.Obj = nil
    self.Epoch = bit.band(NET_EPOCH_MASK, (self.Epoch or 0) + 1)
    self.Domains = {}
    self.Active = false
end

function Slot:MarkActive()
    self.Active = true
    -- TODO: domain stuff
end

--------------------------------------------------------
-- Netmessage send/recv impl


--- Parses slot id/epoch as received via the net, returns corresponding Slot.
-- Does validation:
-- * On SERVER, validates id/epoch's validity, returns nil if invalid.
-- * On CLIENT, creates the slot if ID is invalid yet, flushes the slot if ID is valid but epoch is wrong. 
--
--- obj_id: uint
--- epoch: uint
--- result: Slot|nil -- will be nil if client sends invalid slot id/epoch to server
function Slot.Recv_GetOrAlloc(obj_id, epoch)
    local slot = Slot.Registry.Objects[obj_id]

    if not slot then -- We're receiving data for a new slot.
        if CLIENT then
            -- Server knows better, allocate the slot.
            return Slot:New(obj_id, epoch)
        else
            -- In worst case, some client tries to convince the server that this slot *should* exist.
            -- ...nope, won't alloc.
            return nil 
        end
    end

    if slot.Epoch ~= epoch or slot.Epoch == nil then -- We're receiving data for older or newer contents of the slot.
        if CLIENT then
            -- Server knows better, flush the slot.
            slot:Flush()
            slot.Epoch = epoch
            return slot
        else
            -- In worst case, some client tries to convince the server that the server has past or future value of the slot.
            -- ...nope, won't flush.
            return nil
        end
    end

    -- We have the current version of slot
    return slot
end

--- Read net data for non-Init/Delete netdomain, 
-- delay processing until object init is recieved (if not recieved),
-- and then parse the data using domain's function
--
--- domain_id: uint
--- len: uint -- size of domain-specific data in bits
--- ply: Player|nil -- message sender (nil iff server->client)
function Slot:Recv_Domain(domain_id, len, ply)
    if self.Obj == nil then -- We don't know domains' types and parameters
        assert(CLIENT, "Should never happen (attempt to received data into empty Slot on server)")

        -- Store the raw data, will parse it when object will get inited
        local buf = Net.RecvBuffer(len)
        self.Domains[domain_id] = { Buffer = buf, BufferLen = len }

        return
    end

    local domain = self.Domains[domain_id]
    if domain == nil then return end -- No domain with given ID found, probably bogus net data.

    domain:HandleRecv(Net.RecvCurMessage, len, ply)
end


if CLIENT then
    --- Read net data for Init/Delete netdomain as init message,
    -- construct the object, init it using special Init netdomain,
    -- initialize and handle pending messages from other domains (if any).
    --
    --- len: uint -- remaining data size in bits
    function Slot:Recv_Init(len)
        local typename = net.ReadString()

        local meta = CR.Class.Get(typename)
        if meta == nil then
            CR.Error(self,": received init message for non-existant type ",typename)
        end

        local ctorparam_len = len - (#typename + 1) * 8

        local obj = meta:Construct()
        self.Obj = obj

        local domain_pending = self:Recv_GetPending()

        Domain_Init:SetObject(obj)
        Domain_Init:HandleRecv(Net.RecvCurMessage, len)
        
        obj:Init()

        self:Recv_HandlePending(domain_pending)

    end

    --- Handle delete message
    function Slot:Recv_Delete()
        self:Flush()
    end
end

if SERVER then
    util.AddNetworkString(MSGNAME)
end

net.Receive(MSGNAME, function(len, ply)
    local obj_id = net.ReadUInt(NETID_BITS)
    local epoch = net.ReadUInt(NET_EPOCH_BITS)
    local domain_id = net.ReadUInt(NET_DOMAIN_BITS)

    local slot = Slot.Recv_GetOrAlloc(obj_id, epoch)
    if slot == nil then return end -- Client sent wrong data or tried to fool the server.

    local data_len = len - NETID_BITS - NET_EPOCH_BITS - NET_DOMAIN_BITS

    if domain_id == NET_DOMAIN_INITDELETE then
        -- Only server can tell the receiver (client) to init or delete the slot.
        if SERVER then return end

        -- If there are parameters, it is init message
        if data_len ~= 0 then
            slot:Recv_Init(data_len)
        else
            slot:Recv_Delete()
        end
        return
    end

    slot:Recv_Domain(domain_id, data_len, ply)
end)


--------------------------------------------------------
-- Domain stuff impl

function Slot:AddDomain(domain)
    if self.Obj == nil then
        CR.Error(self, ": called AddDomain but there's no slot")
    end

    if self.Active then
        CR.Error(self, ": called AddDomain on active object (can't add domains to already-fully-created object)")
    end

    if #self.Domains == NET_DOMAIN_MAX then
        CR.Error(self, ": called AddDomain, but there are too many domains already (at max=",NET_DOMAIN_MAX,")")
    end

    -- TODO
end