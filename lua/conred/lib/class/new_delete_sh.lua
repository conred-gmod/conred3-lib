local Class = CR.Class

--- mixin CR.Class.Constructable
--
--- .__isvalid -- false by-default, true during and after call of :Init or :New 
--- .__init_makes_valid = true -- if true, after :Init or :New is called, the object is made valid
--
--- :Construct() static -> object(self) -- construct the object without initializing it
--- :New(ctor_params: ...) static -> object(self) -- construct the object and initialize it
--
--- :Init(ctor_params: ...) -- initialize the object (used when you need to delay init from construction, use :New otherwise)
--- :OnInit(ctor_params: ...) optional
--
--- hook CR.Class.PreInit(obj: object(CR.Class.Constructable), ctor_params: ...)
--- hook CR.Class.PostInit(obj: object(CR.Class.Constructable), ctor_params: ...)

local function class_construct(self)
    local inst = {
        __isvalid = false
    }
    setmetatable(inst, self)

    return inst
end

local function class_init(self, ...)
    if IsValid(self) then
        CR.Error("Can't init ",self,": it is already valid (likely already initialized)")
    end

    hook.Run("CR.Class.PreInit", self, ...)

    if inst.OnInit ~= nil then
        inst:OnInit(...)
    end

    if self.__init_makes_valid then
        self.__isvalid = true
    end

    hook.Run("CR.Class.PostInit", self, ...)
end

local function class_new(self, ...)
    local inst = class_construct(self)
    self:Init(...)

    return inst
end

--- Adds CR.Class.Constructable mixin to `meta`
--- meta: metatable(CR.Class.Base)
function Class.MakeConstructable(meta)
    meta.__isvalid = false
    meta.__init_makes_valid = true

    meta.Construct = class_construct
    meta.Init = class_init
    meta.New = class_new
end

------------------------------------------------------

--- mixin CR.Class.Deletable
--
--- .__isvalid -- set to false after calling :Delete
--
--- :OnDelete(del_params: ...) optional -- the destructor/delete handler (called from delete function if it exists)
--- :Delete(del_params: ...) -- the delete function (can't be called twice)
--
--- hook CR.Class.PreDelete(obj: object(CR.Class.Deletable), del_params: ...)
--- hook CR.Class.PostDelete(obj: object(CR.Class.Deletable), del_params: ...)

local function class_delete(self, ...)
    if not IsValid(self) then
        CR.Error("Can't delete ",self,": it is invalid (likely it is already deleted or was not created (= attempt to delete a metatable))")
    end

    hook.Run("CR.Class.PreDelete", self, ...)

    if self.OnDelete ~= nil then
        self:OnDelete(...)
    end

    self.__isvalid = false

    hook.Run("CR.Class.PostDelete", self, ...)
end

--- Adds CR.Class.Deletable mixin to `meta`
--- In practice should be used together with CR.Class.MakeConstructable.
--
--- meta: metatable(CR.Class.Base) 
function Class.MakeDeletable(meta)
    meta.Delete = class_delete
end