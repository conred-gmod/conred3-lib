---@meta
-- A hack for LuaLS language server to recognize some stuff.


-- Missing GMod stuff
MAX_EDICT_BITS = 0
MAX_PLAYER_BITS = 0

-- Dependencies
NikNaks = NikNaks or {}


-------------

CR = {}
CR.Class = {}
CR.Net = {}

--- Interface for something you can wait for.
---
--- @class CR.Waitable
local Waitable = {}

--- Add callback to be called when the awaited event happens.
--- @param callback fun()
function Waitable:AddReadyCallback(callback)

end

--- Remove callback for awaited event.
--- @param callback fun()
function Waitable:RemoveReadyCallback(callback)

end

--- @class CR.Net.NetConstructable: CR.Net.Networkable, CR.Class.Constructable
local NetConstructable