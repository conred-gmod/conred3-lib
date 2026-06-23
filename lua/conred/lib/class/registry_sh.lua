local Class = CR.Class

--- A persistent registry of some objects
---
--- @class CR.Registry<T>: CR.Class.Constructable
--- @field Name string
--- @field MaxIndex integer? Max index (nil or int>0), adding objects will fail if index > max
--- The registered objects (persisted over hot reloads). 
--- 
--- User is supposed to index or iterate the table. May be non sequential, use `pairs` instead of `ipairs`.
--- @field Objects {[integer]: T}
local REG = Class.Define("CR.Registry")
CR.Registry = REG
Class.MakeConstructable(REG)
CR.MaxIndex = nil

if false then -- For annotations
    --- Creates a named registry
    --- @param name string
    --- @return CR.Registry
    function REG:New(name)
        return REG
    end
end


function REG:OnInit(name)
    assert(isstring(name))

    self.Name = name
    self.Objects = CR.GetPersistedTable(name)
end

function REG:__tostring()
    return "[registry "..self.TypeName..": "..self.Name.."]"
end

--- Returns true if `idx` is a valid index.
---  (`idx` is uint >= 1 and, if there is `.MaxIndex`, `idx <= .MaxIndex`)
--- @param idx integer
--- @return boolean
function REG:ValidateIndex(idx)
    if idx < 1 then return false end
    if bit.tobit(idx) ~= idx then return false end

    if self.MaxIndex == nil then return true end

    return idx <= self.MaxIndex
end

--- Returns adds free index (stil you need to validate it `:ValidateIndex`)
--- 
--- @return integer index
function REG:NextIdx()
    return table.SeqCount(self.Objects) + 1
end

--- Adds the object into registry, returns index of the object
--- @param obj T
--- @return integer
function REG:Add(obj)
    local objs = self.Objects

    local idx = self:NextIdx()
    if not self:ValidateIndex(idx) then
        CR.Error(self,": can't add ",obj,": generated index ",idx," is invalid (min 1, max ", self.MaxIndex, ")")
    end

    objs[idx] = obj
    return idx
end

--- Adds the object into registry with specific index (doesn't have to be sequential)
--- @param obj T
--- @param idx integer
function REG:AddWithId(obj, idx)
    local objs = self.Objects

    if not self:ValidateIndex(idx) then
        CR.Error(self,": can't add ",obj,": provided index ",idx," is invalid (min 1, max ", self.MaxIndex, ")")
    end

    if objs[idx] ~= nil then
        CR.Error(self,": error adding ",obj," with index ",idx,": ", objs[idx]," is already there")
    end

    objs[idx] = obj
end

--- Removes the object at `idx` (errors if there is nothing).
--- @param idx integer
function REG:Remove(idx)
    local objs = self.Objects

    if objs[idx] == nil then
        CR.Error(self, ": error removing object with index ",idx," - there is no object")
    end

    objs[idx] = nil
end