
--- @class CR.Net.Slot
local Slot = CR.Net.Slot

local MSG = "CR.Net.SlotData"
if SERVER then util.AddNetworkString(MSG) end

net.Receive(MSG, function(len, ply)
    
end)




function Slot:Blah()

end

