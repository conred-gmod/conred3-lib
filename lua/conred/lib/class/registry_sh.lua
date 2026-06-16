local Class = CR.Class

--- class CR.Registry
-- A persistent registry of some objects
--
--- :New(name: string) static -> CR.Registry -- creates a named registry
--- .Name: string
--- :__tostring() -> string -- reports the name
--
--- .MaxIndex: nil|nonzero_uint -- max index, adding objects will fail if index > max
--- :ValidateIndex(idx: number) -> bool -- returns true if idx is uint >= 1 and, if there is .MaxIndex, <= .MaxIndex
--
--- .Objects: table(nonzero_uint, obj) -- table of stored objects. 
-- User is supposed to index or iterate the table. May be non sequential, use `pairs` instead of `ipairs`
--- :Add(obj) -> nonzero_uint -- adds the object into registry, returns index of the object
--- :AddWithId(obj, idx: nonzero_uint) -- adds the object into registry with specific index (doesn't have to be sequential)
--- :Remove(idx: nonzero_uint) -- removes the object at `idx` (errors if there is nothing)

local REG = Class.Define("CR.Registry")
CR.Registry = REG
Class.MakeConstructable(REG)
CR.MaxIndex = nil

function REG:OnInit(name)
    assert(isstring(name))

    self.Name = name
    self.Objects = CONRED.GetPersistedTable(name)
end

function REG:__tostring()
    return "[registry "..self.TypeName..": "..self.Name.."]"
end

function REG:ValidateIndex(idx)
    if idx < 1 then return false end
    if bit.tobit(idx) != idx then return false end

    if self.MaxIndex == nil then return true end

    return idx <= self.MaxIndex
end

function REG:Add(obj)
    local objs = self.Objects
    
    local idx = table.SeqCount(objs) + 1
    if not self:ValidateIndex(idx) then
        CR.Error(self,": can't add ",obj,": generated index ",idx," is invalid (min 1, max ", self.MaxIndex, ")")
    end

    objs[idx] = obj
    return idx
end

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

function REG:Remove(idx)
    local objs = self.Objects

    if objs[idx] == nil then
        CR.Error(self, ": error removing object with index ",idx," - there is no object")
    end

    objs[idx] = nil
end