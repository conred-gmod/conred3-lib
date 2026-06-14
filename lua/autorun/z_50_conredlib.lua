local function DoLoad()
    MsgN("ConRed: loading lib")

    AddCSLuaFile("conred/lib/_main_sh.lua")
    include("conred/lib/_main_sh.lua")

    MsgN("ConRed: loaded lib")
end

DoLoad()