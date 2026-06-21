local Class = CR.Class

local classes = CR.GetPersistedTable("CR.Classes")

local function MakeIndex(mt)
    return function(self, k)
        return rawget(mt, k)
    end
end

local function class_tostring(self)
    local invalid_marker = ""
    if not IsValid(self) then
        invalid_marker = " (invalid!)"
    end

    return "[conred class "..tostring(self.TypeName)..invalid_marker.."]"
end

--- metatable CR.Class.Base
-- A class metatable.
-- Class may be "static" (without :New(...)), then the intention is that user calls functions on metatable itself.
--
--- .Base: nil|metatable(CR.Class.Base) (parent class metatable)
--- .TypeName: string
--- :__tostring() -> string -- returns classname and whether object is invalid
--- .__index = .Base or self
--
--- .__isvalid: bool -- true by-default
--- :IsValid() -> bool


local function class_IsValid(self)
    return self.__isvalid == true
end

-- Creates new class metatable (with hot reload support)
--
--- name: string (type name)
--- parent: nil|metatable(CR.Class.Base)
--- returns: metatable(CR.Class.Base)
function Class.Define(name, parent)
    local meta = classes[name]
    if meta and meta.Base == parent then return meta end

    if meta == nil then meta = {} end
    meta.Base = parent
    meta.TypeName = name
    meta.__tostring = class_tostring
    meta.__index = MakeIndex(parent or meta)

    meta.__isvalid = true
    meta.IsValid = class_IsValid

    setmetatable(meta, meta)

    return meta
end

--- Returns class metatable by name
---
--- name: string
--- result: metatable(CR.Class.Base)|nil
function Class.Get(name)
    return classes[name]
end