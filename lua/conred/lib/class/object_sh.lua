---@type {[string]: CR.Class.Base}
local classes = CR.GetPersistedTable("CR.Classes")

---A class metatable.
---Class may be "static" (without :New(...)), then the intention is that user calls functions on metatable itself.
---@class CR.Class.Base
---@field Base CR.Class.Base? Parent class metatable
---@field TypeName string
---@field __isvalid boolean True by-default
---@field __index CR.Class.Base|(fun(CR.Class.Base, string): any?)|nil
local CLASS = {}

--- Returns classname and whether object is invalid
---@return string
function CLASS:__tostring()
    local invalid_marker = ""
    if not IsValid(self) then
        invalid_marker = " (invalid!)"
    end

    return "[conred class "..tostring(self.TypeName)..invalid_marker.."]"
end

function CLASS:IsValid()
    return self.__isvalid == true
end

-- Creates new class metatable (with hot reload support)
--
--- @param name string Typename
--- @param parent CR.Class.Base?
--- @return CR.Class.Base (Metatable)
function CR.Class.Define(name, parent)
    local meta = classes[name]
    if meta and meta.Base == parent then return meta end

---@diagnostic disable-next-line: missing-fields
    if meta == nil then meta = {} end
    table.Merge(meta, CLASS)

    meta.Base = parent
    meta.TypeName = name
    meta.__isvalid = true

    meta.__index = parent

    setmetatable(meta, meta)
    classes[name] = meta
    
    return meta
end

--- Returns class metatable by name
---
--- @param name string
--- @return CR.Class.Base?
function CR.Class.Get(name)
    return classes[name]
end