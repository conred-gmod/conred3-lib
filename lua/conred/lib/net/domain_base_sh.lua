local Class = CR.Class

--- An independent part of a networkable object.
--- @class CR.Net.Domain: CR.Class.Constructable, CR.Class.Deletable
--- @field protected _sendFilter CR.Net.SendFilter?
--- @field protected _recvFilter (fun(Player): boolean)?
--- @field SvToCl boolean
--- @field ClToSv boolean
--- @field Slot CR.Net.Slot
--- @field Id integer
local Domain = Class.Define("CR.Net.Domain")
CR.Net.Domain = Domain

Class.MakeConstructable(Domain)
Class.MakeDeletable(Domain)

Domain.__init_makes_valid = false

function Domain:OnInit(params)
    self._sendFilter = params.SendFilter
    self._recvFilter = params.RecvFilter

    self.SvToCl = params.SvToCl or false
    self.ClToSv = params.ClToSv or false

    if not (self.SvToCl or self.ClToSv) then
        CR.Error(self," is configured as dud (neither SV->CL nor CL->SV)")
    end
end

---**Internal.** Attaches domain to a slot.
---@param slot CR.Net.Slot
---@param id integer
function Domain:Attach(slot, id)
    assert(not self.__isvalid, "Can't attach slot twice")

    self.Slot = slot
    self.Id = id
    self.__isvalid = true
end

---**Internal.** Marks domain as ready to be networked
function Domain:Activate()
    self:OnActivated()
end

---Hook. Called when domain is ready to be networked.
---@protected
function Domain:OnActivated()
    -- Override me
end

---Returns true if sending is allowed in realm where function is called.
---@return boolean
function Domain:CanSend()
    if SERVER then
        return self.SvToCl
    else
        return self.ClToSv
    end
end

---Returns true if receiving is allowed in realm where function is called.
---@return boolean
function Domain:CanRecv()
    if SERVER then
        return self.ClToSv
    else
        return self.SvToCl
    end
end

---Errors if called in realm where sending is not allowed.
---@param ctx string? Additional context for the error message
function Domain:CheckSendAllowed(ctx)
    if not self:CanSend() then
        local realm = SERVER and "SERVER" or "CLIENT"
        local ctx_msg = ""
        if ctx then
            ctx_msg = " :"..ctx
        end

        CR.Error(self, ": can't do send stuff on ",realm,ctx_msg)
    end
end

---Errors if called in realm where receiving is not allowed.
---@param ctx string? Additional context for the error message
function Domain:CheckRecvAllowed(ctx)
    if not (SERVER and self.ClToSv) and not (CLIENT and self.SvToCl) then
        local realm = SERVER and "SERVER" or "CLIENT"
        local ctx_msg = ""
        if ctx then
            ctx_msg = " :"..ctx
        end

        CR.Error(self, ": can't do recv stuff on ",realm,ctx_msg)
    end
end

-------------------------------------------------------------------------------


---Starts a domain net message to opposite realm.
---@protected
---@param unreliable boolean?
function Domain:Net_Start(unreliable)
    self.Slot:Net_StartDomain(self.Id, unreliable)
end

---Sends a domain net message to opposite realm.
---
---@protected
---@param sf CR.Net.SendFilter|Player[]|CRecipientFilter? On SERVER, a sendfilter or array of recieving players or a recipientfilter or a domain sendfilter if nil. On CLIENT, ignored. 
function Domain:Net_Send(sf)
    if SERVER and sf == nil then
        sf = self._sendFilter
    end

    if sf and sf.GetArray then
        sf = sf:GetArray()
    end
    ---@cast sf Player[]|CRecipientFilter?

    self.Slot:Net_SendDomain(sf)
end

---Checks if recieving data from given player should be allowed (via recvfilter).
---
---In case of SV->CL, allows everything if domain itself allows SV->CL.
---@protected
---@param ply Player?
---@return boolean
function Domain:Net_CheckRecv(ply)
    if not self:CanRecv() then return false end
    if CLIENT then return true end

    if self._recvFilter then
        return self._recvFilter(ply)
    end

    return true
end

---Hook. Called when sendfilter changes its value
---@protected
---@param added boolean
---@param removed boolean
function Domain:Net_OnRecvListChanged(added, removed)
    -- Override me
end



--- Called in `net.Recieve` context. Read netmessage sent to domain here.
--- @param len integer Length of message to domain in bits (excluding aux info like domain ID, slot ID and the like.)
--- @param ply Player? On SERVER, player who sent this message. On CLIENT, nil.
function Domain:Net_RecvData(len, ply)
    if not self:Net_CheckRecv(ply) then return end

    self:Net_OnRecvData(len, ply)
end

--- Hook. Called in `net.Recieve` context. Read netmessage sent to domain here.
--- @param len integer Length of message to domain in bits (excluding aux info like domain ID, slot ID and the like.)
--- @param ply Player? On SERVER, player who sent this message. On CLIENT, nil.
function Domain:Net_OnRecvData(len, ply)
    assert(false, "Override and implement me")
end
