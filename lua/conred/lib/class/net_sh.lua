
local Class = CR.Class

local msgname = "CR.Class.Networking"
if SERVER then
    util.AddNetworkString(msgname)
end

Class.NETID_BITS = 16
Class.NETID_MAX = bit.lshift(1, Class.NETID_BITS) - 1

Class.NET_EPOCH_BITS = 12
Class.NET_EPOCH_MASK = 4095

Class.NET_DOMAIN_BITS = 8
Class.NET_DOMAIN_INITDELETE = 0 --- Id of InitDelete netdomain
Class.NET_DOMAIN_MAX = 255

----------------------------------------------

local NetSlot = Class.Define("CR.Class.NetSlot")
Class.MakeConstructable(NetSlot)

--- NetSlot.ObjId: uint
--- NetSlot.Obj: CR.Class.Networkable|nil
--- NetSlot.Epoch: uint|nil
--- NetSlot.Domains: table(domainid: uint, domain: CR.Class.NetDomain)

-- Stores `NetSlot`s
NetSlot.Registry = CR.Registry:New("CR.Class.NetSlot.Registry")

--- NetSlot:New(obj_id: uint, epoch: uint|nil) -> object(self)
function NetSlot:OnInit(obj_id, epoch)
    self.ObjId = obj_id
    self.Epoch = epoch
    self.Domains = {}
end

function NetSlot:__tostring()
    local obj = self.Obj and tostring(self.Obj) or "[unconstructed object]"
    local epoch = self.Epoch and ("epoch "..tostring(self.Epoch)) or "unset epoch"

    return "[slot for "..obj.." w/ id "..tostring(self.ObjId).." at "..epoch"]"
end

function NetSlot.Alloc(obj_id, epoch)
    local slot = NetSlot:New(obj_id, epoch)
    NetSlot.Registry:AddWithId(slot, obj_id)

    return slot
end


if CLIENT then
    --- Delete slot's object if it exists and deletable
    function NetSlot:Flush()
        if IsValid(obj) then 
            if obj.Delete ~= nil then
                obj:Delete()
            else
                ErrorNoHalt("Attempt to flush ",self," with undeletable object.\n",
                "Server is giving wrong commands, pls report to devs. (This won't break anything by itself.)")
            end
        end

        self.Obj = nil
        self.Epoch = nil
        self.Domains = {}
    end
end

if SERVER then
    function NetSlot:IncreaseEpoch()
        self.Epoch = bit.band(Class.NET_EPOCH_MASK, self.Epoch + 1)
    end
end

--- Parses slot id/epoch as received via the net, returns corresponding NetSlot.
-- Does validation:
-- * On SERVER, validates id/epoch's validity, returns nil if invalid.
-- * On CLIENT, creates the slot if ID is invalid yet, flushes the slot if ID is valid but epoch is wrong. 
--
--- obj_id: uint
--- epoch: uint
--- result: NetSlot|nil -- will be nil if client sends invalid slot id/epoch to server
function NetSlot.HandleReceive_GetOrAlloc(obj_id, epoch)
    local slot = NetSlot.Registry.Objects[obj_id]

    if not slot then -- We're receiving data for a new slot.
        if CLIENT then
            -- Server knows better, allocate the slot.
            return NetSlot.Alloc(obj_id, epoch)
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
function NetSlot:HandleReceive_Domain(domain_id, len, ply)
    if self.Obj == nil then -- We don't know domains' types and parameters
        assert(CLIENT, "Should never happen (attempt to received data into empty netslot on server)")

        -- Store the raw data, will parse it when object will get inited
        local buf = Class.NetRecvBuffer(len)
        self.Domains[domain_id] = { Buffer = buf, BufferLen = len }

        return
    end

    local domain = self.Domains[domain_id]
    if domain == nil then return end -- No domain with given ID found, probably bogus net data.

    domain:HandleRecv(Class.NetRecvCurMessage, len, ply)
end


if CLIENT then
    --- Read net data for Init/Delete netdomain as init message,
    -- construct the object, init it using special Init netdomain,
    -- initialize and handle pending messages from other domains (if any).
    --
    --- len: uint -- remaining data size in bits
    function NetSlot:HandleReceive_Init(len)

    end
end

local function net_HandleReceive(len, ply)
    local obj_id = net.ReadUInt(Class.NETID_BITS)
    local epoch = net.ReadUInt(Class.NET_EPOCH_BITS)
    local domain_id = net.ReadUInt(Class.NET_DOMAIN_BITS)

    local slot = NetSlot.HandleReceive_GetOrAlloc(obj_id, epoch)
    if slot == nil then return end -- Client sent wrong data or tried to fool the server.

    local data_len = len - CLASS.NETID_BITS - CLASS.NET_EPOCH_BITS - CLASS.NET_DOMAIN_BITS

    if domain_id == NET_DOMAIN_INITDELETE then
        -- Only server can tell the receiver (client) to init or delete the slot.
        if SERVER then return end

        -- If there are parameters, it is init message
        if data_len ~= 0 then
            slot:HandleReceive_Init(data_len)
        else
            slot:HandleReceive_Delete()
        end
        return
    end

    slot:HandleReceive_Domain(domain_id, data_len, ply)
end
net.Receive("CR.Class.Networking", net_HandleReceive)



-------------------------------------

--- mixin CR.Class.Networkable
-- An object that supports networking between client and server.
--
--

--- Adds CR.Class.Networkable to `meta`.
-- Can be used for static objects w/o constructors.
--
--- meta: metatable(CR.Class.Base)
function Net.MakeNetworkable(meta)

end