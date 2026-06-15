local Class = CR.Class

--- mixin CR.Class.Constructable
--
--- .__isvalid -- false by-default, true after calling :New
--
--- :Init(ctor_params: ...) optional -- the initializer (called from constructor if it exists)
--- :New(ctor_params: ...) static -> object(self) -- the constructor function 

local function class_new(self, ...)
    local inst = {
        __isvalid = true
    }

    setmetatable(inst, self)

    if inst.Init ~= nil then
        inst:Init(...)
    end

    return inst
end

--- Adds CR.Class.Constructable mixin to `meta`
--- meta: metatable(CR.Class.Base)
function Class.MakeConstructable(meta)
    meta.__isvalid = false
    meta.New = class_new
end


--- mixin CR.Class.Destructable
--
--- .__isvalid -- set to false after calling :Remove
--
--- :OnRemove(remove_params: ...) optional -- the destructor/remove handler (called from remove function if it exists)
--- :Remove(remove_params: ...) -- the remove function (can't be called twice)

local function class_remove(self, ...)
    if not IsValid(self) then
        CR.Error("Can't remove ",self,": it is invalid (likely it is already removed or was not created (= attempt to remove a metatable))")
    end

    if self.OnRemove ~= nil then
        self:OnRemove(...)
    end

    self.__isvalid = false
end

--- Adds CR.Class.Removable mixin to `meta`
--- In practice should be used together with CR.Class.MakeConstructable.
--
--- meta: metatable(CR.Class.Base) 
function Class.MakeRemovable(meta)
    meta.Remove = class_remove
end