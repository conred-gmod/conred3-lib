local BitBuffer = NikNaks.BitBuffer

--- class CR.Net.RecvBuffer
-- A class that reads data from current net recieve into a buffer
-- and provides all net.Read* functions to parse the data later.
--
-- No resetting is available. All methods are called via :
-- (buf:ReadBool(), buf:ReadTable())

local RB = CR.Class.Define("CR.Net.RecvBuffer")
CR.Net.RecvBuffer = RB

CR.Class.MakeConstructable(RB)

function RB:OnInit(len)
    self._buf = BitBuffer:ReadFromNet(len)
end



function RB:ReadBit()
    return self._buf:ReadBoolean() and 1 or 0
end

function RB:ReadBool()
    return self._buf:ReadBoolean()
end

function RB:ReadInt(bitCount)
    return self._buf:ReadInt(bitCount)
end

function RB:ReadUInt(bitCount)
    return self._buf:ReadUInt(bitCount)
end

function RB:ReadFloat()
    return self._buf:ReadFloat()
end

function RB:ReadDouble()
    return self._buf:ReadFloat()
end

function RB:ReadUInt64()
    assert(false, "unimplemented yet")
end



function RB:ReadAngle()
    assert(false, "unimplemented yet")
end

function RB:ReadVector()
    assert(false, "unimplemented yet")
end

function RB:ReadNormal()
    assert(false, "unimplemented yet")
end

function RB:ReadMatrix()
    assert(false, "unimplemented yet")
end


function RB:ReadColor(hasalpha)
    local r, g, b = self._buf:ReadByte(), self._buf:ReadByte(), self._buf:ReadByte()

    local a = 255
    if hasalpha then a = self._buf:ReadByte() end

    return Color(r,g,b,a)
end




function RB:ReadString()
    return self._buf:ReadStringNull()
end

function RB:ReadData(length)
    return self._buf:ReadData(length)
end



function RB:ReadEntity()
    return Entity(self._buf:ReadUInt(MAX_EDICT_BITS))
end

function RB:ReadPlayer()
    return Entity(self._buf:ReadUInt(MAX_PLAYER_BITS))
end

local handlers = {
    [TYPE_NIL]		= function ()	return nil end,
    [TYPE_STRING]	= RB.ReadString,
    [TYPE_NUMBER]	= RB.ReadDouble,
    [TYPE_TABLE]	= RB.ReadTable,
    [TYPE_BOOL]		= RB.ReadBool,
    [TYPE_ENTITY]	= RB.ReadEntity,
    [TYPE_VECTOR]	= RB.ReadVector,
    [TYPE_ANGLE]	= RB.ReadAngle,
    [TYPE_MATRIX]	= RB.ReadMatrix,
    [TYPE_COLOR]	= RB.ReadColor,
}

function RB:ReadType(typeid)
    typeid = typeid or self._buf:ReadUInt(8)
    local handler = handlers[typeid]
    if handler == nil then
        CR.Error("Error reading type with invalid typeid ",typeid)
    end

    return handler(self)
end

function RB:ReadTable(sequential)
    local tbl = {}

    if sequential then
        for i = 1, self._buf:ReadUInt(32) do
            tbl[i] = self:ReadType()
        end
    else
        while true do
            local k = self:ReadType()
            if k == nil then break end

            tbl[k] = self:ReadType()
        end
    end

    return tbl
end


--- class CR.Net.RecvCurMessage
-- Basically all net.Read* functions but with added `self` first argument.
-- To be used instead of CR.Class.NetRecvBuffer
local RCM = CR.Class.Define("CR.Net.RecvCurMessage")
CR.Net.RecvCurMessage = RCM

function RCM:ReadBit()
    return net.ReadBit()
end

function RCM:ReadBool()
    return net.ReadBool()
end

function RCM:ReadInt(bitCount)
    return net.ReadInt(bitCount)
end

function RCM:ReadUInt(bitCount)
    return net.ReadUInt(bitCount)
end

function RCM:ReadFloat()
    return net.ReadFloat()
end

function RCM:ReadDouble()
    return net.ReadDouble()
end

function RCM:ReadUInt64()
    return net.ReadUInt64()
end



function RCM:ReadAngle()
    return net.ReadAngle()
end

function RCM:ReadVector()
    return net.ReadVector()
end

function RCM:ReadNormal()
    return net.ReadNormal()
end

function RCM:ReadMatrix()
    return net.ReadMatrix()
end


function RCM:ReadColor(hasalpha)
    return net.ReadColor(hasalpha)
end




function RCM:ReadString()
    return net.ReadString()
end

function RCM:ReadData(length)
    return net.ReadData(length)
end



function RCM:ReadEntity()
    return net.ReadEntity()
end

function RCM:ReadPlayer()
    return net.ReadPlayer()
end

function RCM:ReadType(typeid)
    return net.ReadType(typeid)
end

function RCM:ReadTable(sequential)
    return net.ReadTable(sequential)
end
