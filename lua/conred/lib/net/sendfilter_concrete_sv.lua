local Class = CR.Class
local SFA = CR.Net.SendFilterArray

--- A send filter that contains players matching some predicate.
--- @class CR.Net.PredicateSendFilter: CR.Net.SendFilterArray
--- @field _pred fun(Player): boolean
local PSF = Class.Define("CR.Net.PredicateSendFilter", SFA)
CR.Net.PredicateSendFilter = PSF

PSF.NotifyPlayerConnected = true

function PSF:OnInit(predicate)
    SFA.OnInit(self)

    self._pred = predicate
end

function PSF:OnDelete()
    self._pred = nil -- For GC

    SFA.OnDelete(self)
end

---Call this when predicate value for player `ply` is changed.
---
---(You can call it when value stays the same, but preferrably don't.)
---@param ply Player
---@param notify boolean|nil If false, filter changed callbacks won't be called automatically. Call `:NotifyChanged(added, removed)` manually. 
---@return boolean added Was the player added to the filter?
---@return boolean removed Was the player removed from the filter?
function PSF:NotifyPredicateValChanged(ply, notify)
    local new_val = self._pred(ply)

    if new_val then
        if self:AddPlayer(ply, notify) then
            return true, false
        end
    else
        if self:RemovePlayer(ply, notify) then
            return false, true
        end
    end

    return false, false
end

function PSF:OnPlayerConnected(ply)
    if self._pred(ply) then
        self:AddPlayer(ply)
    end
end