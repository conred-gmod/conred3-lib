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


--- mixin CR.Class.Deletable
--
--- .__isvalid -- set to false after calling :Delete
--
--- :OnDelete(del_params: ...) optional -- the destructor/delete handler (called from delete function if it exists)
--- :Delete(del_params: ...) -- the delete function (can't be called twice)

local function class_delete(self, ...)
    if not IsValid(self) then
        CR.Error("Can't delete ",self,": it is invalid (likely it is already deleted or was not created (= attempt to delete a metatable))")
    end

    if self.OnDelete ~= nil then
        self:OnDelete(...)
    end

    self.__isvalid = false
end

--- Adds CR.Class.Deletable mixin to `meta`
--- In practice should be used together with CR.Class.MakeConstructable.
--
--- meta: metatable(CR.Class.Base) 
function Class.MakeDeletable(meta)
    meta.Delete = class_delete
end