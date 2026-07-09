local Class = CR.Class

--- @class CR.Net.SendFilter: CR.Class.Constructable, CR.Class.Deletable
--- @field private _callbacks fun(added: boolean, removed: boolean)[]
--- @field NotifyPlayerConnected boolean Static, false by-default.
--- @field NotifyPlayerDisconnected boolean Static, false by-default.
local SF = Class.Define("CR.Net.SendFilter")
CR.Net.SendFilter = SF

Class.MakeConstructable(SF)
Class.MakeDeletable(SF)

SF.NotifyPlayerConnected = false
SF.NotifyPlayerDisconnected = false

--- @type CR.Net.SendFilter[]
local filters = CR.GetPersistedTable("CR.Net.SendFilter.List")

function SF:OnInit()
    self._callbacks = {}

    if self.NotifyPlayerConnected or self.NotifyPlayerDisconnected then
        table.insert(filters, self)
    end
end

function SF:OnDelete()
    if self.NotifyPlayerConnected or self.NotifyPlayerDisconnected then
        table.RemoveFastByValue(filters, self)
    end

    self._callbacks = nil
end

---Call this function when player list was changed
---@param added boolean
---@param removed boolean
function SF:NotifyChanged(added, removed)
    for _, cb in ipairs(self._callbacks) do
        cb(added, removed)
    end
end

---Add new callback to be called on player list change.
---@param cb fun(added: boolean, removed: boolean)
function SF:AddChangedCallback(cb)
    local cbs = self._callbacks

    if not table.HasValue(cbs, cb) then
        table.insert(cbs, cb)
    end
end

---Remove a callback added with `:AddChangedCallback`.
---@param cb fun(added: boolean, removed: boolean)
function SF:RemoveChangedCallback(cb)
    table.RemoveFastByValue(self._callbacks, cb)
end

---Returns players passing the filter.
---@return Player[]
function SF:GetArray()
    assert(false, "Unimplemented")
end

---Returns recipient filter matching this.
---@return CRecipientFilter
function SF:GetRecipientFilter()
    assert(false, "Unimplemented")
end

---Returns best representation of the filter.
---@return Player[]|CRecipientFilter
function SF:GetBestRepr()
    assert(false, "Unimplemented")
end

---Returns true if no player currently match the filter.
---@return boolean
function SF:IsEmpty()
    assert(false, "Unimplemented")
end

---**Hook.** Called when `ply` is connected if `.NotifyPlayerConnected == true`
---@protected
---@param ply Player
function SF:OnPlayerConnected(ply)
    -- Override me in child class
end

---**Hook.** Called when `ply` is disconnected if `.NotifyPlayerDisconnected == true`
---@protected
---@param ply Player
function SF:OnPlayerDisconnected(ply)
    -- Override me in child class
end


hook.Add("PlayerInitialSpawn", "CR.Net.NotifiedSendFilter", function(ply)
    if ply:IsBot() then return end

    for _, sf in ipairs(filters) do
        if sf.NotifyPlayerConnected then
            sf:OnPlayerConnected(ply) ---@diagnostic disable-line: invisible
        end
    end
end)

hook.Add("PlayerDisconnected", "CR.Net.NotifiedSendFilter", function(ply)
    if ply:IsBot() then return end

    for _, sf in ipairs(filters) do
        if sf.NotifyPlayerDisconnected then
            sf:OnPlayerDisconnected(ply) ---@diagnostic disable-line: invisible
        end
    end
end)

-------------------------------------------------------------------------------

--- @class CR.Net.SendFilterArray: CR.Net.SendFilter
--- @field protected _players Player[]
local SFA = Class.Define("CR.Net.SendFilterArray", SF)
CR.Net.SendFilterArray = SFA

SFA.NotifyPlayerDisconnected = true

function SFA:OnInit()
    SF.OnInit(self)

    self._players = {}
end

function SFA:GetArray() return self._players end

function SFA:GetBestRepr() return self._players end

function SFA:IsEmpty() return table.IsEmpty(self._players) end

function SFA:GetRecipientFilter()
    local recip = RecipientFilter()
    recip:AddPlayers(self._players)
    return recip
end

function SFA:OnPlayerDisconnected(ply)
    self:RemovePlayer(ply)
end

---Add a player to the filter, if he is not already there.
---@protected
---@param ply Player
---@param notify boolean|nil If false, filter changed callbacks won't be called.
---@return boolean added Player was added.
function SFA:AddPlayer(ply, notify)
    assert(IsValid(ply))

    local plys = self._players
 
    if table.SeqHasValue(plys, ply) then
        return false
    end

    table.insert(plys, ply)

    if notify ~= false then
        self:NotifyChanged(true, false)
    end

    return true
end

---Remove a player from the filter, if he is there.
---@protected
---@param ply Player
---@param notify boolean|nil If false, filter changed callbacks won't be called.
---@return boolean removed Player was removed.
function SFA:RemovePlayer(ply, notify)
    if table.RemoveFastByValue(self._players, ply) == nil then
        return false
    end

    if notify ~= false then
        self:NotifyChanged(false, true)
    end

    return true
end