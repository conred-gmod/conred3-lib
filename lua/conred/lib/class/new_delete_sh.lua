local Class = CR.Class

--- mixin CR.Class.Constructable
--
--- .__isvalid -- false by-default, true during and after call of :Init or :New 
--
--- :Construct() static -> object(self) -- construct the object without initializing it
--- :New(ctor_params: ...) static -> object(self) -- construct the object and initialize it
--
--- :Init(ctor_params) -- initialize the object (used when you need to delay init from construction, use :New otherwise)
--- :OnInit(ctor_params: ...) optional

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
    
    self.__isvalid = true

    if inst.OnInit ~= nil then
        inst:OnInit(...)
    end

end

local function class_new(self, ...)
    local inst = class_construct(self)
    class_init(self, ...)

    return inst
end

--- Adds CR.Class.Constructable mixin to `meta`
--- meta: metatable(CR.Class.Base)
function Class.MakeConstructable(meta)
    meta.__isvalid = false

    meta.Construct = class_construct
    meta.Init = class_init
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