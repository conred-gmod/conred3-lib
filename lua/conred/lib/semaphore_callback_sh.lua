
--- interface CR.Waitable
-- Something you can wait for.
--
--- :AddReadyCallback(callback: fn()) -- Add callback to be called when the awaited event happens.
--- :RemoveReadyCallback(callback: fn()) -- Remove the callback


--- class CR.SemaphoredCallback
--- impl CR.Class.Constructable, CR.Class.Deletable
-- A callback with semaphore (wait counter).
--
--
--- :New() static -> CR.SemaphoredCallback
--- :Delete() -- Cleans up Waitable references (should help free some memory)

--- :Wait() -- Adds another event/condition to wait for.
--- :Unwait() -- Indicate that some awaited event happened.
-- (Call this as many times as :Wait() was called to execute the callbacks)
--
--- :WaitFor(waitable: CR.Waitable) -- Makes the semaphore wait for `waitable`. Call :Delete() on the semaphore if you are using this.
--
--- :DoOnce(callback: fn()) -- Adds callback to execute once after all waited events are happened.
--- :DoRepeating(callback: fn()) -- Adds callback to execute each time after all waited events are happened.
--- :CancelOnce(callback: fn()) -- Remove callback added by :DoOnce
--- :CancelRepeating(callback: fn()) -- Remove callback added by :DoRepeating

local SC = CR.Class.Define("CR.SemaphoredCallback")
CR.SemaphoredCallback = SC

CR.Class.MakeConstructable(SC)
CR.Class.MakeDeletable(SC)

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


function SC:Wait()
    self._waitCount = self._waitCount + 1
end

function SC:WaitFor(waitable)
    assert(waitable.AddWaitDoneCallback)

    self:Wait()
    waitable:AddReadyCallback(self.Unwait_Static)
    table.insert(self._waitables, waitable)
end

function SC:Unwait()
    assert(self._waitCount > 0, "Attempt to unwait a semaphore callback without waiting first")

    self._waitCount = self._waitCount - 1
    self:_TryExecuteCallback()
end



function SC:DoOnce(callback)
    if self._waitCount == 0 then
        callback()
        return
    end

    table.insert(self._callbacksOnce, callback)
end

function SC:DoRepeating(callback)
    if self._waitCount == 0 then
        callback()
    end

    table.insert(self._callbacks, callback)
end

function SC:CancelOnce(callback)
    table.RemoveByValue(self._callbacksOnce, callback)
end

function SC:CancelRepeating(callback)
    table.RemoveByValue(self._callbacksRepeating, callback)
end