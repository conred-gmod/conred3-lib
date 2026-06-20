
local Class = CR.Class

local MSGNAME = "CR.Net.DomainMessage"

-------------------------------------

--- mixin CR.Net.Networkable
-- An object that supports networking between client and server.
--
--- .IsNetworkable = true
--- .Net_Slot: CR.Net.Slot
--
--- :Net_Setup() abstract -- called before :OnInit, implement it and configure net stuff here.
--- :Net_StaticInitialized() -- for static classes (w/o :Init), call this after all initialization is done to activate networking.
--
-- Set/call following functions in :Net_Setup impl
--- .Net_SendFilter: CR.Net.SendFilter|nil 
--- :Net_AddDomain(domain: CR.Net.Domain) -> domain -- Adds domain to the networkable object. Max 255 domains per object. 
--
--- :Net_SendInit() optional -- called in net.Start context. Write networked ctor params here.
--- :Net_RecvInit(buf: CR.Net.IRecvReader len: uint) optional -- called in net.Receive context, `self` is not valid yet. Read networked ctor params here.


local function net_PreInit(obj)
    if SERVER then
    -- Create a slot for obj
    -- obj.Net_Slot = slot
    else
        -- Check that the object was created via net
    end


    if obj.Net_Setup == nil then
        CR.Error("Networkable ",obj," lacks implemented :NetSetup()")
    end

    obj:Net_Setup()

    obj.Net_Slot:ConfigureInit(obj.Net_SendFilter, obj.Net_SendInit, obj.Net_RecvInit)
end

local function net_PostInit(obj)
    -- obj.Net_Slot: <<mark as initialized, ready to tx/rx>>
end

local function net_PostDelete(obj)
    -- obj.Net_Slot: <<flush>>
end

hook.Add("CR.Class.PreInit", "CR.Net.Networkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PreInit(obj)
end)

hook.Add("CR.Class.PostInit", "CR.Net.Networkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PostInit(obj)
end)

local function net_StaticInitialized(obj)
    assert(obj.IsNetworkable, "Not a Networkable")
    
    if obj.Init ~= nil or obj.New ~= nil or obj.Construct ~= nil then
        CR.Error("Attempt to use :Net_StaticInitialized on non-static class ",obj)
    end

    -- TODO: clean slot explicitly?

    net_PreInit(obj)
    net_PostInit(obj)
end

hook.Add("CR.Class.PostDelete", "CR.Net.Networkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PostDelete(obj)
end)


--- Adds CR.Net.Networkable to `meta`.
-- Can be used on static objects w/o constructors.
--
--- meta: metatable(CR.Class.Base)
function CR.Net.MakeNetworkable(meta)
    self.IsNetworkable = true

    self.Net_StaticInitialized = net_StaticInitialized
    self.Net_AddDomain = net_AddDomain
end