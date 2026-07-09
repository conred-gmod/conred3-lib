local Class = CR.Class

--- A send filter. Contains CRecipientFilter and provides callbacks when players are added to/removed from it.
--- 
--- @class CR.Net.SendFilter: CR.Class.Constructable, CR.Class.Deletable
--- @field private _callbacks fun(added: boolean, removed: boolean)[]
--- @field NotifyPlayerConnected boolean Static, false by-default.
--- --@field NotifyPlayerDisconnected boolean Static, false by-default.
--- @field RecipFilter CRecipientFilter 
local SF = Class.Define("CR.Net.SendFilter")
CR.Net.SendFilter = SF

Class.MakeConstructable(SF)
Class.MakeDeletable(SF)

SF.IsSendFilter = true
SF.NotifyPlayerConnected = false
--SF.NotifyPlayerDisconnected = false

--- @type CR.Net.SendFilter[]
local filters = CR.GetPersistedTable("CR.Net.SendFilter.List")

function SF:OnInit()
    self.RecipFilter = RecipientFilter()

    self._callbacks = {}

    if self.NotifyPlayerConnected --[[or self.NotifyPlayerDisconnected]] then
        table.insert(filters, self)
    end
end

function SF:OnDelete()
    if self.NotifyPlayerConnected --[[or self.NotifyPlayerDisconnected]] then
        table.RemoveFastByValue(filters, self)
    end

    self._callbacks = nil
end

---Call this function when player list was changed.
---@param added boolean
---@param removed boolean
function SF:NotifyChanged(added, removed)
    if not added or removed then return end

    for _, cb in ipairs(self._callbacks) do
        cb(added, removed)
    end
end

---Add new callback to be called on player list change.
---
---The callback will not be called on player disconnection.
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

---Returns true if no player currently match the filter.
---@return boolean
function SF:IsEmpty()
    return self.RecipFilter:GetCount() == 0
end

---**Hook.** Called when `ply` is connected if `.NotifyPlayerConnected == true`
---@protected
---@param ply Player
function SF:OnPlayerConnected(ply)
    -- Override me in child class
end

--[[
---**Hook.** Called when `ply` is disconnected if `.NotifyPlayerDisconnected == true`
---@protected
---@param ply Player
function SF:OnPlayerDisconnected(ply)
    -- Override me in child class
end
]]


hook.Add("PlayerInitialSpawn", "CR.Net.NotifiedSendFilter", function(ply)
    if ply:IsBot() then return end

    for _, sf in ipairs(filters) do
        if sf.NotifyPlayerConnected then
            sf:OnPlayerConnected(ply) ---@diagnostic disable-line: invisible
        end
    end
end)

--[[
hook.Add("PlayerDisconnected", "CR.Net.NotifiedSendFilter", function(ply)
    if ply:IsBot() then return end

    for _, sf in ipairs(filters) do
        if sf.NotifyPlayerDisconnected then
            sf:OnPlayerDisconnected(ply) ---@diagnostic disable-line: invisible
        end
    end
end)
]]

-------------------------------------------------------------------------------

--- A sendfilter with its inner recipientfilter being reset each update.
--- @class CR.Net.ResettingSendFilter: CR.Net.SendFilter
--- @field private _recipfilt_tmp1 CRecipientFilter
--- @field private _recipfilt_tmp2 CRecipientFilter
--- @field private _autoupdate boolean
local RSF = CR.Class.Define("CR.Net.ResettingSendFilter", SF)
CR.Net.ResettingSendFilter = RSF

function RSF:OnInit()
    SF.OnInit(self)

    self._recipfilt_tmp1 = RecipientFilter() -- Cache two temp filters for added/removed players calculation.
    self._recipfilt_tmp2 = RecipientFilter()
    self._autoupdate = false
end

function RSF:OnDelete()
    self:DisableAutoupdate()

    SF.OnDelete(self)
end

---Call this to re-compute the filter.
---@return boolean added
---@return boolean removed
function RSF:TryUpdate()
    local filt = self.RecipFilter

    local filt_old = self._recipfilt_tmp1
    filt_old:AddPlayers(filt)
    local old_cnt = filt_old:GetCount()

    filt:RemoveAllPlayers()
    self:DoFilter(filt)
    local new_cnt = filt_old:GetCount()

    local added = new_cnt > old_cnt
    if not added then
        local filt_added = self._recipfilt_tmp2 -- not (new - old):IsEmpty()
        filt_added:AddPlayers(filt)
        filt_added:RemovePlayers(filt_old) 
        added = filt_added:GetCount() ~= 0
    end

    local removed = new_cnt < old_cnt
    if not removed then
        local filt_removed = filt_old
        filt_removed:RemovePlayers(filt) -- not (old - new):IsEmpty()
        removed = filt_removed:GetCount() ~= 0
    end

    self:NotifyChanged(added, removed)

    return added, removed
end

---**Hook.** Add whatever you want to `filt`.
---@protected
---@param filt CRecipientFilter
function RSF:DoFilter(filt)
    assert(false, "Override me!")
end

---@type CR.Net.ResettingSendFilter[]
local autoupdate = CR.GetPersistedTable("CR.ResettingSendFilter.AutoUpdate")

---Make the filter update automatically each server think
function RSF:EnableAutoupdate()
    if self._autoupdate then return end

    table.insert(autoupdate, self)
    self._autoupdate = true
end

--- Stop the filter from updating automatically each server think
function RSF:DisableAutoupdate()
    if not self._autoupdate then return end

    table.RemoveFastByValue(autoupdate, self)
    self._autoupdate = false
end

hook.Add("Think", "CR.ResettingSendFilter.AutoUpdater", function()
    for _, sf in ipairs(autoupdate) do
        sf:TryUpdate()
    end
end)

-------------------------------------------------------------------------------

--- @class CR.Net.CompositeSendFilter: CR.Net.SendFilter
--- @field protected _dependencies CR.Net.SendFilter[]
local CSF = CR.Class.Define("CR.Net.CompositeSendFilter", SF)
CR.Net.CompositeSendFilter = CSF

function CSF:OnInit()
    SF.OnInit(self)

    self._dependencies = {}
    self._changedCallback = function(added, removed) self:DependencyChanged(added, removed) end
end

---Adds a dependency to the composite sendfilter. 
---@param dep CR.Net.SendFilter
function CSF:AddDependency(dep)
    if table.SeqHasValue(self._dependencies, dep) then return end

    table.insert(self._dependencies, dep)
    dep:AddChangedCallback(self._changedCallback)

    if not dep:IsEmpty() then
        self:DependencyChanged(true, false)
    end
end

---Removes a dependency from the composite sendfilter. 
---@param dep CR.Net.SendFilter
function CSF:RemoveDependency(dep)
    if not table.SeqHasValue(self._dependencies, dep) then return end

    table.RemoveFastByValue(self._dependencies, dep)
    dep:RemoveChangedCallback(self._changedCallback)

    if not dep:IsEmpty() then
        self:DependencyChanged(false, true)
    end
end

function CSF:OnDelete()
    for _, dep in ipairs(self._dependencies) do
        dep:RemoveChangedCallback(self._changedCallback)
    end
    self._dependencies = nil

    SF.OnDelete(self)
end


---@private
---@param added boolean
---@param removed boolean
function CSF:DependencyChanged(added, removed)
    self:Recompute()
    self:NotifyChanged(added, removed)
end

---**Hook.** Recompute composite recipientfilter here.
---@protected
function CSF:Recompute()
    assert(false, "Unimplemented")
end