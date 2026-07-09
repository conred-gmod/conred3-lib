local Class = CR.Class

--- @class CR.Net.SendFilter: CR.Class.Constructable, CR.Class.Deletable
--- @field private _callbacks fun(added: boolean, removed: boolean)[]
local SF = Class.Define("CR.Net.SendFilter")
CR.Net.SendFilter = SF

Class.MakeConstructable(SF)
Class.MakeDeletable(SF)

function SF:OnInit()
    self._callbacks = {}
end

function SF:OnDelete()
    self._callbacks = nil
end

---Call this function when player list was changed
---@protected
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

-------------------------------------------------------------------------------

--- @class CR.Net.SendFilterArray: CR.Net.SendFilter
--- @field protected _players Player[]
local SFA = Class.Define("CR.Net.SendFilterArray", SF)
CR.Net.SendFilterArray = SFA

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
