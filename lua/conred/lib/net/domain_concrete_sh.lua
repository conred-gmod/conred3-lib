local Class = CR.Class
local Domain = CR.Net.Domain

--- @class CR.Net.DomainEvent<T>: CR.Net.Domain
--- @field _send fun(self: CR.Net.DomainEvent, data: T)
--- @field _onRecv fun(self: CR.Net.DomainEvent, len: integer, ply: Player?)
--- @field Unreliable boolean?
local DE = Class.Define("CR.Net.DomainEvent", Domain)
CR.Net.DomainEvent = DE

function DE:OnInit(params)
    Domain.OnInit(self, params)

    self.Unreliable = params.Unreliable

    self._send = params.Send
    self._onRecv = params.OnRecv
end

---Sends the event according to recvfilter (on SERVER) or to server (on CLIENT).
---
---@param data T Event data.
function DE:Send(data)
    self:CheckSendAllowed()

    self:Net_Start(self.Unreliable)
        self:_send(data)
    self:Net_Send()
end

function DE:Net_OnRecvData(len, ply)
    self:_onRecv(len, ply)
end

-------------------------------------------------------------------------------

--- @class CR.Net.DomainVar: CR.Net.Domain
--- @field AutoActivate boolean
--- @field ValidVersionPlayers CRecipientFilter? Exists on SERVER in SV->CL domains
--- @field _send fun(self: CR.Net.DomainVar)? Exists in send realms.
--- @field _onRecv fun(self: CR.Net.DomainVar, len: integer, ply: Player?) Exits in recv realms.
--- @field Unreliable boolean?
local DV = Class.Define("CR.Net.DomainVar", Domain)
CR.Net.DomainVar = DV

function DV:OnInit(params)
    Domain.OnInit(self, params)

    self.Unreliable = params.Unreliable

    self._send = self:CanSend() and params.Send or nil
    self._recv = self:CanRecv() and params.OnRecv or nil

    self.AutoActivate = params.AutoActivate or true

    if SERVER and self.SvToCl then
        self.ValidVersionPlayers = RecipientFilter()
    end
end

function DV:OnActivated()
    if self.AutoActivate and self:CanSend() then
        self:MarkUpdated()
    end
end

--- Call this when the data is changed
function DV:MarkUpdated()
    self:CheckSendAllowed(":MarkUpdated()")

    self:Send(true)
end

---@private
---@param versionChanged boolean
---@return CRecipientFilter|Player[]|nil Recipients (if SV->CL and there were any) 
function DV:SendImpl(versionChanged)
    local txfilter = nil

    if SERVER then
        if self._sendFilter:IsEmpty() then return end

        local txlist = self._sendFilter:GetBestRepr()
        txfilter = txlist

        if not versionChanged then
            -- Only keep players who have obsolete versions of data

            txfilter = RecipientFilter()
            txfilter:AddPlayers(txlist)
            txfilter:RemovePlayers(self.ValidVersionPlayers)

            if txfilter:GetCount() == 0 then return end
        else
            -- Just send data to players who are in sendfilter
        end
    end

    self:Net_Start(self.Unreliable)
        self:_send()
    self:Net_Send(txfilter)

    return txfilter
end

---Sends data to the opposite realm.
---@private
---@param versionChanged boolean
function DV:Send(versionChanged)
    local txfilter = self:SendImpl(versionChanged)

    if SERVER then
        if versionChanged then
            -- Version changed = list of actual version players have just became invalid
            self.ValidVersionPlayers:RemoveAllPlayers()
        end
        if txfilter then
            -- We've actually sent data to someone -> recipients have just became a valid version players 
            self.ValidVersionPlayers:AddPlayers(txfilter)
        end
    end
end

function DV:Net_OnRecvData(len, ply)
    self:_onRecv(len, ply)
end

if SERVER then
    function DV:Net_OnRecvListChanged(added)
        if added then
            self:Send(false)
        end
    end
end

-------------------------------------------------------------------------------
