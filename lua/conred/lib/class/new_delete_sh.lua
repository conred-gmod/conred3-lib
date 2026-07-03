--- `CR.Class.Constructable`-related hooks:
--- @hook CR.Class.PreInit(obj: CR.Class.Constructable, ctor_params: ...)
--- @hook CR.Class.PostInit(obj: CR.Class.Constructable, ctor_params: ...)

--- A mixin that makes it possible to create instances of the class.
--- 
--- Use `CR.Class.MakeConstructable` to add me to your metatable.
--- 
--- @class CR.Class.Constructable: CR.Class.Base
--- @field IsStatic false
--- @field __init_makes_valid boolean If true, after `:Init` or `:New` is called, the object is made valid. True by-default.
--- @field __isvalid boolean False by-default, true during and after `:Init` or `:New`.
--- @field OnInit (fun(self: CR.Class.Constructable, ...))? User-defined initializer.
local CONSTR = {}

CONSTR.IsStatic = false

--- Construct the object without initializing it.
--- 
--- @return CR.Class.Constructable Unintialized object instance
function CONSTR:Construct()
    local inst = {
        __isvalid = false
        -- TODO: __index and other metatable hooks
    }
    setmetatable(inst, self)

    return inst
end

--- Initialize the object.
---  
--- Useful when you need to separated init from construction, use `:New` otherwise.
--- 
--- @param ... any? Initializer params (passed into `:OnInit`)
function CONSTR:Init(...)
    if IsValid(self) then
        CR.Error("Can't init ",self,": it is already valid (likely already initialized)")
    end

    hook.Run("CR.Class.PreInit", self, ...)

    if self.OnInit ~= nil then
        self:OnInit(...)
    end

    if self.__init_makes_valid then
        self.__isvalid = true
    end

    hook.Run("CR.Class.PostInit", self, ...)
end

--- Construct the object and initialize it.
--- 
--- @param ... any? Initializer params (passed into `:OnInit`
--- @return CR.Class.Constructable Initialized object instance
function CONSTR:New(...)
    local inst = self:Construct()
    inst:Init(...)

    return inst
end

--- Adds `CR.Class.Constructable` mixin to `meta`
--- 
--- @param meta CR.Class.Base
function CR.Class.MakeConstructable(meta)
    table.Merge(meta, CONSTR)

    -- We *are* injecting stuff, this *is* a mixin, after all.
---@diagnostic disable: inject-field
    meta.__isvalid = false
    meta.__init_makes_valid = true
---@diagnostic enable: inject-field
end

------------------------------------------------------

--- A mixin that adds static initialization to static class.
--- 
--- Use `CR.Class.MakeStaticInitable` to add me to your metatable.
---
--- @class CR.Class.StaticInitable: CR.Class.Base
--- @field IsStatic true
--- @field __isvalid boolean False by-default, true during and after `:StaticInit` (if .__delayStaticInit == false) or `:StaticInit_Delayed`
--- @field __delayStaticInit boolean False by-default, if true, static init will be delayed until `:StaticInit_Delayed` is called
--- @field private __staticInitStarted boolean
--- @field OnStaticInit (fun(self: CR.Class.StaticInitable))? Callback 
local STINIT = {}

STINIT.__isvalid = false
STINIT.IsStatic = true
STINIT.__delayStaticInit = false
STINIT.__staticInitStarted = false

--- Initialize static object. Call this after everything is added to the metatable.
function STINIT:StaticInit()
    self.__staticInitStarted = true

    if not self.__delayStaticInit then
        self:StaticInit_Delayed()
    end
end

--- Do the delayed initialization of static object.
--- 
--- Do not call if delayed init (`.__delayStaticInit`) is disabled. It will error.
function STINIT:StaticInit_Delayed()
    assert(self.__staticInitStarted and not self.__isvalid)

    if self.OnStaticInit ~= nil then
        self:OnStaticInit()
    end

    self.__isvalid = true
end

---Adds `CR.Class.StaticInitable` mixin to `meta`
---@param meta CR.Class.Base
function CR.Class.MakeStaticInitable(meta)
    table.Merge(meta, CONSTR)
end

------------------------------------------------------

--- `CR.Class.Deletable`-related hooks:
--- @hook CR.Class.PreDelete(obj: CR.Class.Deletable)
--- @hook CR.Class.PostDelete(obj: CR.Class.Deletable)

--- A mixin that makes it possible to delete objects.
--- 
--- Intended to be used with `CR.Class.Constructable`, but may be used on its own.
--- @class CR.Class.Deletable: CR.Class.Base
--- @field __isvalid boolean Set to false after calling :Delete
--- @field OnDelete fun(CR.Class.Deletable)? User-defined destructor/delete handler
local DEL = {}

--- The delete function. 
--- 
--- Can't be called twice (or, if the type is `CR.Class.Constructable`, on metatables or on uninitialized objects).
function DEL:Delete()
    if not IsValid(self) then
        CR.Error("Can't delete ",self,": it is invalid (likely it is already deleted or was not created (= attempt to delete a metatable))")
    end

    hook.Run("CR.Class.PreDelete", self)

    if self.OnDelete ~= nil then
        self:OnDelete()
    end

    self.__isvalid = false

    hook.Run("CR.Class.PostDelete", self)
end

--- Adds CR.Class.Deletable mixin to `meta`
--- In practice should be used together with CR.Class.MakeConstructable.
--
--- @param meta CR.Class.Base (Fields are added)
function CR.Class.MakeDeletable(meta)
    table.Merge(meta, DEL)
end

---Deletes `obj` if it is non-nil and valid.
---@param obj CR.Class.Deletable?
---@return boolean wasDeleted
function CR.Class.TryDelete(obj)
    if IsValid(obj) and obj.Delete then
        obj:Delete()
        return true
    end

    return false
end