local Class = CR.Class
local SF = CR.Net.SendFilter
local RSF = CR.Net.ResettingSendFilter
local CSF = CR.Net.CompositeSendFilter

--- A send filter that contains players matching some predicate.
--- @class CR.Net.PredicateSendFilter: CR.Net.SendFilter
--- @field _pred fun(Player): boolean
local PSF = Class.Define("CR.Net.PredicateSendFilter", SF)
CR.Net.PredicateSendFilter = PSF

PSF.NotifyPlayerConnected = true

function PSF:OnInit(predicate)
    SF.OnInit(self)

    self._pred = predicate
end

if false then -- For annotations
    ---Creates new PredicateSendFilter
    ---@param predicate fun(Player): boolean
    ---@return CR.Net.PredicateSendFilter
    function PSF:New(predicate)
        return PSF
    end
end


function PSF:OnDelete()
    self._pred = nil -- For GC

    SF.OnDelete(self)
end

---Call this when predicate value for player `ply` is changed.
---
---(You can call it when value stays the same, but preferrably don't.)
---@param ply Player
---@return boolean added Was the player added to the filter?
---@return boolean removed Was the player removed from the filter?
function PSF:NotifyPredicateValChanged(ply)
    local rf = self.RecipFilter
    local val = self._pred(ply)

    local old_cnt = rf:GetCount()
    if val then
        rf:AddPlayer(ply)
    else
        rf:RemovePlayer(ply)
    end
    local new_cnt = rf:GetCount()
    local added = new_cnt > old_cnt
    local removed = new_cnt < old_cnt

    self:NotifyChanged(added, removed)

    return added, removed
end

function PSF:OnPlayerConnected(ply)
    if not self._pred(ply) then return end

    local rf = self.RecipFilter

    local old_cnt = rf:GetCount()
    rf:AddPlayer(ply)
    local new_cnt = rf:GetCount()

    local added = new_cnt > old_cnt
    self:NotifyChanged(added, false)
end

-------------------------------------------------------------------------------

---A sendfilter that includes all players who can potentially see a certain position
---@class CR.Net.PVSSendFilter: CR.Net.ResettingSendFilter
---@field pos_cb fun():Vector
local PVSF = CR.Class.Define("CR.Net.PVSSendFilter", RSF)
CR.Net.PVSSendFilter = PVSF

function PVSF:OnInit(pos_cb)
    RSF.OnInit(pos_cb)

    self._pos_cb = pos_cb
end

if false then -- For annotations
    ---Creates new PVSSendFilter
    ---@param pos_cb fun():Vector
    ---@return CR.Net.PVSSendFilter
    function PVSF:New(pos_cb)
        return PVSF
    end
end

function PVSF:DoFilter(filt)
    filt:AddPVS(self._pos_cb())
end

---A sendfilter that includes all players who can potentially hear a certain position
---@class CR.Net.PASSendFilter: CR.Net.ResettingSendFilter
---@field pos_cb fun():Vector
local PASF = CR.Class.Define("CR.Net.PASSendFilter", RSF)
CR.Net.PASSendFilter = PASF

function PASF:OnInit(pos_cb)
    RSF.OnInit(pos_cb)

    self._pos_cb = pos_cb
end

if false then -- For annotations
    ---Creates new PASSendFilter
    ---@param pos_cb fun():Vector
    ---@return CR.Net.PASSendFilter
    function PASF:New(pos_cb)
        return PASF
    end
end

function PASF:DoFilter(filt)
    filt:AddPAS(self._pos_cb())
end

-------------------------------------------------------------------------------

---A composite sendfilter that OR-s all its sub-netfilters.
---@class CR.Net.OrSendFilter: CR.Net.CompositeSendFilter
local ORSF = CR.Class.Define("CR.Net.OrSendFilter", CSF)

function ORSF:OnInit(filters)
    CSF.OnInit(self)

    for _, filter in ipairs(filters) do
        self:AddDependency(filter)
    end
end

if false then -- For annotations
    ---Creates new OrSendFilter
    ---@param filters CR.Net.SendFilter[] Array of OR-ed sendfilters. 
    ---@return CR.Net.OrSendFilter
    function ORSF:New(filters)
        return ORSF
    end
end

function ORSF:Recompute()
    local rf = self.RecipFilter
    rf:RemoveAllPlayers()

    for _, dep in ipairs(self._dependencies) do
        rf:AddPlayers(dep.RecipFilter)
    end
end

-------------------------------------------------------------------------------

---A composite sendfilter that AND-s all its sub-netfilters.
---Becomes empty if there are no sub-netfilters.
---@class CR.Net.AndSendFilter: CR.Net.CompositeSendFilter
local ANDSF = CR.Class.Define("CR.Net.OrSendFilter", CSF)

function ANDSF:OnInit(filters)
    CSF.OnInit(self)

    for _, filter in ipairs(filters) do
        self:AddDependency(filter)
    end
end

if false then -- For annotations
    ---Creates new AndSendFilter
    ---@param filters CR.Net.SendFilter[] Array of AND-ed sendfilters. 
    ---@return CR.Net.AndSendFilter
    function ANDSF:New(filters)
        return ANDSF
    end
end

function ANDSF:Recompute()
    local rf = self.RecipFilter
    if table.IsEmpty(self._dependencies) then
        rf:RemoveAllPlayers()
        return
    end

    rf:AddAllPlayers()
    for i, dep in ipairs(self._dependencies) do
        rf:RemoveMismatchedPlayers(dep.RecipFilter)
    end
end

-------------------------------------------------------------------------------

--- A composite sendfilter that matches everything in *main* but not in *sub*, that is, substracts *sub* from *main*.
--- @class CR.Net.SubSendFilter: CR.Net.SendFilter
--- @field private _main CR.Net.SendFilter
--- @field private _sub CR.Net.SubSendFilter
local SUBSF = CR.Class.Define("CR.Net.SubSendFilter", SF)

function SUBSF:OnInit(main, sub)
    SF.OnInit(self)

    self._main = main
    self._sub = sub

    self._mainChanged = function(added, removed) self:MainChanged(added, removed) end
    self._subChanged = function(added, removed) self:SubChanged(added, removed) end

    self._main:AddChangedCallback(self._mainChanged)
    self._sub:AddChangedCallback(self._subChanged)

    self:Recompute()
    self:NotifyChanged(self.RecipFilter:GetCount() ~= 0, false)
end

if false then -- For annotations
    ---Creates new SubSendFilter
    ---@param main CR.Net.SendFilter The *main* sendfilter.
    ---@param sub CR.Net.SendFilter The *sub* (substracted) sendfilter.
    ---@return CR.Net.SubSendFilter
    function SUBSF:New(main, sub)
        return SUBSF
    end
end


function SUBSF:OnDelete()
    self._main:RemoveChangedCallback(self._mainChanged)
    self._sub:RemoveChangedCallback(self._subChanged)

    SF.OnDelete(self)
end

---@private
---@param added boolean
---@param removed boolean
function SUBSF:MainChanged(added, removed)
    self:Recompute()
    self:NotifyChanged(added, removed)
end

---@private
---@param added boolean
---@param removed boolean
function SUBSF:SubChanged(added, removed)
    self:Recompute()
    self:NotifyChanged(removed, added)
end

---@private
function SUBSF:Recompute()
    local rf = self.RecipFilter
    rf:RemoveAllPlayers()
    rf:AddPlayers(self._main.RecipFilter)
    rf:RemovePlayers(self._sub.RecipFilter)
end