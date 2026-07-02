local Class = CR.Class

--- @class CR.Net.SendFilter: CR.Class.Constructable, CR.Class.Deletable
local SF = Class.Define("CR.Net.SendFilter")
CR.Net.SendFilter = SF

function SF:NotifyChanged()
    
end

Class.MakeConstructable(SF)
Class.MakeDeletable(SF)

--- @class CR.Net.NotifiedSendFilter: CR.Net.SendFilter
--- @field _players Player[]
--- @field _filter fun(Player): boolean
local NOTIFF = Class.Define("CR.Net.NotifiedSendFilter", SF)

--- @type CR.Net.NotifiedSendFilter[]
local filters = CR.GetPersistedTable("CR.Net.NotifiedSendFilter.List")

function NOTIFF:OnInit(filter)
    self.Base.OnInit(self)

    self._players = {}
    self._filter = filter

    table.insert(filters, self)
end

function NOTIFF:OnDelete()
    table.RemoveFastByValue(filters, self)

    self._filter = nil

    self.Base.OnDelete(self)
end

--- @param ply Player
function NOTIFF:_Add(ply)
    if table.SeqHasValue(self._players, ply) then
        return false
    end

    if not self._filter(ply) then
        return false
    end

    table.insert(self._players, ply)
    self:NotifyChanged()

    return true
end

--- @param ply Player
function NOTIFF:_Remove(ply)
    local old_idx = table.RemoveFastByValue(self._players, ply)

    if old_idx == nil then
        return false
    end

    self:NotifyChanged()
    return true
end

---Call this when callback value for player `ply` is changed.
---
---(You can call it when value stays the same, but preferrably don't.)
---@param ply any
function NOTIFF:NotifyFilterValueChanged(ply)
    local new_val = self._filter(ply)

    if new_val then
        self:_Add(ply)
    else
        self:_Remove(ply)
    end
end

hook.Add("PlayerInitialSpawn", "CR.Net.NotifiedSendFilter", function(ply)
    if ply:IsBot() then return end

    for _, nsf in ipairs(filters) do
        nsf:_Add(ply)
    end
end)

hook.Add("PlayerDisconnected", "CR.Net.NotifiedSendFilter", function(ply)
    if ply:IsBot() then return end

    for _, nsf in ipairs(filters) do
        if IsValid(nsf) then
            nsf:_Remove(ply)
        end
    end
end)