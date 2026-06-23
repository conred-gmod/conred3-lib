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


--- A class (maybe static) that provides all the net.Read* functions
--- @class CR.Net.IRecvReader
local RR = {}

---@return 0|1
function RR:ReadBit()
end

---@return boolean
function RR:ReadBool()
end

---@param bitCount integer
---@return integer
function RR:ReadInt(bitCount)
end

---@param bitCount integer
---@return integer
function RR:ReadUInt(bitCount)
end

---@return number
function RR:ReadFloat()
end

---@return number
function RR:ReadDouble()
end

---@return string uint64 as a decimal string
function RR:ReadUInt64()
end

---@return Angle
function RR:ReadAngle()
end

--- @return Vector
function RR:ReadVector()
end

--- @return Vector
function RR:ReadNormal()
end

--- @return VMatrix
function RR:ReadMatrix()
end

--- @param hasalpha boolean?
--- @return Color
function RR:ReadColor(hasalpha)
end

--- @return string
function RR:ReadString()
end

--- @param length integer
--- @return string
function RR:ReadData(length)
end

--- @return Entity
function RR:ReadEntity()
end

--- @return Player
function RR:ReadPlayer()
end

--- @param typeid TYPE
--- @return any
function RR:ReadType(typeid)
end

--- @param sequential boolean?
--- @return table
function RR:ReadTable(sequential)
end
