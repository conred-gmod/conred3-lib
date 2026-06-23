

--- A callback with semaphore (wait counter).
---
---@class CR.SemaphoredCallback: CR.Class.Constructable, CR.Class.Deletable
---@field private _waitCount integer
---@field private _callbacksOnce fun()[]
---@field private _callbacks fun()[]
---@field private _waitables CR.Waitable[]
---
---@field Unwait_Static fun() The same as `self:Unwait()`, but as a lambda function.
local SC = CR.Class.Define("CR.SemaphoredCallback")
CR.SemaphoredCallback = SC

CR.Class.MakeConstructable(SC)
CR.Class.MakeDeletable(SC)

if false then -- For annotations
    --- Creates a new semaphored callback with no awaited events.
    --- @return CR.SemaphoredCallback
    function SC:New()
        return SC
    end

    --- Cleans up `CR.Waitable` references (should help free some memory)
    function SC:Delete()

    end
end

function SC:OnInit()
    self._waitCount = 0
    self._callbacksOnce = {}
    self._callbacks = {}
    self._waitables = {}

    self.Unwait_Static = function() self:Unwait() end
end

function SC:OnDelete()
    for _, waitable in ipairs(self._waitables) do
        if IsValid(waitable) then
            waitable:RemoveReadyCallback(self.Unwait_Static)
        end
    end
end

function SC:_TryExecuteCallbacks()
    -- Waiting for something
    if self._waitCount ~= 0 then return end

    for _, fn in ipairs(self._callbacksOnce) do
        fn()
    end
    self._callbacksOnce = {}

    for _, fn in ipairs(self._callbacks) do
        fn()
    end
end

--- Adds another event/condition to wait for.
function SC:Wait()
    self._waitCount = self._waitCount + 1
end

--- Makes the semaphore wait for `waitable`. 
--- 
--- Call :Delete() on the semaphore if you are using this to free some memory.
--- @param waitable CR.Waitable
function SC:WaitFor(waitable)
    assert(waitable.AddReadyCallback)

    self:Wait()
    waitable:AddReadyCallback(self.Unwait_Static)
    table.insert(self._waitables, waitable)
end

--- Indicate that some awaited event happened.
--- 
--- (Call this as many times as :Wait() was called to execute the callbacks)
function SC:Unwait()
    assert(self._waitCount > 0, "Attempt to unwait a semaphore callback without waiting first")

    self._waitCount = self._waitCount - 1
    self:_TryExecuteCallbacks()
end


--- Adds callback to execute once after all waited events are happened.
--- @param callback fun()
function SC:DoOnce(callback)
    if self._waitCount == 0 then
        callback()
        return
    end

    table.insert(self._callbacksOnce, callback)
end

--- Adds callback to execute each time after all waited events are happened.
--- @param callback fun()
function SC:DoRepeating(callback)
    if self._waitCount == 0 then
        callback()
    end

    table.insert(self._callbacks, callback)
end

--- Remove callback added by :DoOnce
--- @param callback fun()
function SC:CancelOnce(callback)
    table.RemoveByValue(self._callbacksOnce, callback)
end

--- Remove callback added by :DoRepeating
--- @param callback fun()
function SC:CancelRepeating(callback)
    table.RemoveByValue(self._callbacks, callback)
end