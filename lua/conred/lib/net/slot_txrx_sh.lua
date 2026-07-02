
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



net.Receive(MSG, function(len, ply)
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
            local typename = net.ReadString()
            userdata_len = userdata_len - 8 * (#typename + 1)

            slot:Net_RecvConstructor(typename, gen, userdata_len)
        end

        return
    end

    local domain = slot._domains[domain_id]
    if domain == nil then
        return
    end

    domain:Net_RecvData(userdata_len, ply)
end)

if CLIENT then
    ---@param typename string
    ---@param gen integer
    ---@param userdata_len integer
    function Slot:Net_RecvConstructor(typename, gen, userdata_len)
        if self.Gen ~= gen and self.Gen ~= bit.band(gen - 1, GEN_MASK) then
            MsgN(self, ": got constructor message (typename ",typename,", gen ",gen,"), but skipped some generations")
        end

        self:Flush()
        self:SetGen(gen)

        local meta = CR.Class.Get(typename) --[[@as CR.Net.NetConstructable?]]

        if meta == nil then
            CR.Error(self,": got constructor message for ",typename,", but no such object exist")
        elseif not meta.IsNetworkable then
            CR.Error(self,": got constructor message for ",typename,", but it is not a networkable class")
        end
        ---@cast meta -nil
    
        if meta.Construct ~= nil then
            self:Net_RecvConstructor_NonStatic(meta, userdata_len)
        else
            self:Net_RecvConstructor_Static(meta, userdata_len)
        end
    end

    ---@param meta CR.Net.Networkable
    ---@param userdata_len integer
    function Slot:Net_RecvConstructor_Static(meta, userdata_len)
        -- TODO
    end

    ---@param meta CR.Net.NetConstructable
    ---@param userdata_len integer
    function Slot:Net_RecvConstructor_NonStatic(meta, userdata_len)
        -- TODO
    end
end