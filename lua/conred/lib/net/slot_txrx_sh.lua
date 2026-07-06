local Class = CR.Class
local Domain = CR.Net.Domain

local SLOT_BITS = CR.Net.SLOT_BITS
local GEN_BITS = CR.Net.GEN_BITS
local DOMAIN_BITS = CR.Net.DOMAIN_BITS
local GEN_MASK = CR.Net.GEN_MASK

--- @class CR.Net.Slot
local Slot = CR.Net.Slot

local MSG = "CR.Net.SlotData"
if SERVER then util.AddNetworkString(MSG) end

---**Internal.**
---
---Starts domain netmessage.
---@param domain_id integer Domain ID
---@param unreliable boolean|nil If true, message will be send unreliably.
function Slot:Net_StartDomain(domain_id, unreliable)
    net.Start(MSG, unreliable)

    net.WriteUInt(self.Id, SLOT_BITS)
    net.WriteUInt(self.Gen, GEN_BITS)
    net.WriteUInt(domain_id, DOMAIN_BITS)
end

---**Internal.**
---
---Sends domain netmessage to `recip`
---@param recip CRecipientFilter|Player[]|nil nil on CLIENT, non-nil on SERVER
function Slot:Net_SendDomain(recip)
    if CLIENT then
        net.SendToServer()
    else
        ---@cast recip -nil
        net.Send(recip)
    end
end

local function Slot_RecvMsg(len, ply)
    local slot_id = net.ReadUInt(SLOT_BITS)
    local gen = net.ReadUInt(GEN_BITS)
    local domain_id = net.ReadUInt(DOMAIN_BITS)
    local userdata_len = len - SLOT_BITS - GEN_BITS - DOMAIN_BITS

    local slot = Slot._registry.Objects[slot_id]

    if slot == nil or slot.Gen ~= gen then -- got data for invalid slot or invalid version of slot
        if SERVER then -- CL->SV: ignore it, don't even log it (so that scriptkiddies won't cause log spam)
            return
        end

        if domain_id ~= 0 then
            if slot then
                ErrorNoHalt("CR.Net.Slot: recieved netmessage for slot ",slot," domain ",domain_id,", but generation is wrong (",gen,", not ",slot.Gen")")
            else
                ErrorNoHalt("CR.Net.Slot: recieved netmessage for empty slot [#",slot_id,", gen ",gen,"] domain ",domain_id)
            end

            return
        end

        if userdata_len == 0 then -- Destructor
            if slot == nil then -- Nothing to destruct
                return -- Handle as if slot was already destructed
            end
        else -- Constructor
            if slot == nil then
                slot = Slot:New(slot_id)
            end
            slot:Flush()
            slot:SetGen(gen)
        end
    end
    ---@cast slot -nil

    if domain_id == 0 then
        if SERVER then return end

        if userdata_len == 0 then -- Destructor
            if slot ~= nil then
                slot:Flush()
                slot:SetGen(gen + 1)
            end
        else -- Constructor
            slot:Net_RecvConstructor(gen, userdata_len)
        end

        return
    end

    local domain = slot._domains[domain_id]
    if domain == nil then
        return
    end

    domain:Net_RecvData(userdata_len, ply)
end

net.Receive(MSG, Slot_RecvMsg)

---@param obj CR.Net.Networkable
function Slot:AssignAndConfigureAndSetup(obj)
    obj.Net_Slot = self
    self:AssignAndConfigure(obj)
    obj:Net_Setup()
end

if CLIENT then
    ---@param gen integer
    ---@param userdata_len integer
    function Slot:Net_RecvConstructor(gen, userdata_len)
        local typename = net.ReadString()
        userdata_len = userdata_len - 8 * (#typename + 1)

        if self.Gen ~= gen and self.Gen ~= bit.band(gen - 1, GEN_MASK) then
            MsgN(self, ": got constructor message (typename ",typename,", gen ",gen,"), but skipped some generations")
        end

        local meta = CR.Class.Get(typename) --[[@as CR.Net.Networkable]]

        if meta == nil then
            CR.Error(self,": got constructor message for ",typename,", but no such object exist")
        elseif not meta.IsNetworkable then
            CR.Error(self,": got constructor message for ",typename,", but it is not a networkable class")
        end
        ---@cast meta -nil
    
        ---@type CR.Net.InstanceNetworkable|CR.Net.StaticNetworkable
        local obj

        if meta.IsStatic == false then
            ---@cast meta CR.Net.InstanceNetworkable
            obj = meta:Construct() --[[@as CR.Net.InstanceNetworkable]]
        elseif meta.IsStatic == true then
            ---@cast meta CR.Net.StaticNetworkable
            if not meta.__staticInitStarted then
                CR.Error(self,": receiving net init for static object ",meta,", which wasn't static initied yet")
            end

            obj = meta
        else
            CR.Error(self, ": got constructor message for ",meta," which is neither constructable nor (explicitly) static.")
        end

        self:Flush()
        self:SetGen(gen)

        self:AssignAndConfigureAndSetup(obj)
        self._domainInit:Net_RecvData(userdata_len)

        if obj.IsStatic then
            obj:StaticInit_Delayed()
        else 
            obj:Init()
        end

        self:Activate()
    end
end

---@param obj CR.Net.Networkable
local function net_PreInit(obj)
    if CLIENT then
        if obj.Net_Slot == nil then
            CR.Error("Networkable ",obj," was created by client, not by server via networking. (.Net_Slot == nil)")
        end
        return
    end

    local slot

    if obj.IsStatic and obj.Net_Slot ~= nil then -- Hot reload
        slot = obj.Net_Slot
        slot:Flush()
    else
        slot = Slot:GetEmpty()
    end
    
    slot:AssignAndConfigureAndSetup(obj)
end

---@param obj CR.Net.Networkable
local function net_PostInit(obj)
    if CLIENT then return end

    obj.Net_Slot:Activate()
end

hook.Add("CR.Class.PreInit", "CR.Net.InitSlotOnNetworkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PreInit(obj)
end)

hook.Add("CR.Class.PreStaticInit", "CR.Net.InitSlotOnNetworkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PreInit(obj)
end)

if SERVER then
    hook.Add("CR.Class.PostInit", "CR.Net.InitSlotOnNetworkable", function(obj)
        if not obj.IsNetworkable then return end

        net_PostInit(obj)
    end)

    hook.Add("CR.Class.PostStaticInit", "CR.Net.InitSlotOnNetworkable", function(obj)
        if not obj.IsNetworkable then return end

        net_PostInit(obj)
    end)
end

--- @param obj CR.Net.InstanceNetworkable
local function net_PostDelete(obj)
    obj.Net_Slot:Flush()
end

hook.Add("CR.Class.PostDelete", "CR.Net.FlushSlotOnNetworkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PostDelete(obj)
end)

--- A special domain used to pass object constructor parameters and destructor calls from server to client.
--- 
--- @class CR.Net.DomainInit: CR.Net.Domain
--- @field Object CR.Net.Networkable
--- @field InitedPlayers CRecipientFilter? Exists on SERVER
local DI = Class.Define("CR.Net.DomainInit", Domain)
CR.Net.DomainInit = DI

---@param obj CR.Net.Networkable
---@param sf CR.Net.SendFilter?
function DI:OnInit(obj, sf)
    Domain.OnInit(self, {
        SvToCl = true,
        ClToSv = false,
        SendFilter = sf
    })

    self.Object = obj

    if SERVER then
        self.InitedPlayers = RecipientFilter()
    end
end

if SERVER then
    ---@private
    function DI:SendInit()
        if self._sendFilter:IsEmpty() then return end

        local txfilter = RecipientFilter()
        txfilter:AddPlayers(self._sendFilter:GetBestRepr())
        txfilter:RemovePlayers(self.InitedPlayers)

        if self._sendFilter:IsEmpty() then return end

        self:Net_Start()
            net.WriteString(self.Object.TypeName) -- Parsed in Slot:Net_RecvConstructor above
            self.Object:Net_SendInit()
        self:Net_Send(txfilter)

        self.InitedPlayers:AddPlayers(txfilter)
    end

    ---@private
    function DI:SendRemove()
        self:Net_Start()
        self:Net_Send(self.InitedPlayers) -- Parsed in Slot_RecvMsg above

        self.InitedPlayers:RemoveAllPlayers()
    end

    ---@param added boolean
    function DI:Net_OnRecvListChanged(added)
        if added then self:SendInit() end
    end

    function DI:OnActivated()
        self:SendInit()
    end

    function DI:OnDelete()
        self:SendRemove()

        Domain.OnDelete(self)
    end
else
    function DI:Net_OnRecvData(len)
        -- TypeName parsed in Slot:Net_RecvConstructor
        self.Object:Net_RecvInit(len)
    end
end


if false then -- For annotations
    ---Makes new init domain
    ---@param obj CR.Net.Networkable
    ---@param sf CR.Net.SendFilter? SERVER-only
    ---@return CR.Net.DomainInit
    function DI:New(obj, sf)
        return DI
    end
end