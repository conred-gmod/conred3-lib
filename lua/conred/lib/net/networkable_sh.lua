

--- A mixin for object that supports networking between client and server.
--- 
--- Supports static classes as well.
---
--- @class CR.Net.Networkable: CR.Class.Base
--- @field IsNetworkable true
--- @field Net_Slot CR.Net.Slot
--- 
--- @field Net_Setup fun(CR.Net.Networkable) Called before :OnInit, implement it and configure net stuff here.
--- @field Net_SendFilter CR.Net.SendFilter? Optional sendfilter used for this object. Set it in `:Net_Setup`.
local NETABLE = {}

NETABLE.IsNetworkable = true

--- @param obj CR.Net.Networkable
local function net_PreInit(obj)
    if SERVER then
        obj.Net_Slot = CR.Net.Slot:GetEmpty()
    else
        if obj.Net_Slot == nil then
            CR.Error("Networkable ",obj," was created by client, not by server via networking. (.Net_Slot == nil)")
        end
    end

    if obj.Net_Setup == nil then
        CR.Error("Networkable ",obj," lacks implemented :NetSetup()")
    end

    obj.Net_Slot:AssignAndConfigure(obj)

    obj:Net_Setup()
end

--- @param obj CR.Net.Networkable
local function net_PostInit(obj)
    obj.Net_Slot:Activate()
end

--- @param obj CR.Net.Networkable
local function net_PostDelete(obj)
    obj.Net_Slot:Flush()
end

hook.Add("CR.Class.PreInit", "CR.Net.Networkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PreInit(obj)
end)

hook.Add("CR.Class.PostInit", "CR.Net.Networkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PostInit(obj)
end)

--- Marks the static networkable class as initialized, activates networking.
--- 
--- Will error if used on non-static object.
function NETABLE:StaticInitialized()
    local maybe_ctorable = self --[[@as CR.Class.Constructable]]
    if maybe_ctorable.Init ~= nil or maybe_ctorable.New ~= nil or maybe_ctorable.Construct ~= nil then
        CR.Error("Attempt to use :Net_StaticInitialized on non-static class ",maybe_ctorable)
    end

    if self.Net_Slot ~= nil then
        self.Net_Slot:Flush()
    end

    net_PreInit(self)
    net_PostInit(self)
end

hook.Add("CR.Class.PostDelete", "CR.Net.Networkable", function(obj)
    if not obj.IsNetworkable then return end

    net_PostDelete(obj)
end)

--- Adds domain to the networkable object. Max 255 domains per object. 
--- 
--- Call me in `:Net_Setup` only.
--- @param domain CR.Net.Domain
--- @return CR.Net.Domain # `= domain`
function NETABLE:AddDomain(domain)
    self.Net_Slot:AddDomain(domain)

    return domain
end

if SERVER then
    --- Called in `net.Start` context. Override and write networked ctor params here.
    --- 
    --- SERVER-only.
    function NETABLE:Net_SendInit()
        -- To be overriden
    end
else
    --- Called in `net.Receive` context, `self` is not valid yet. Override and read networked ctor params here.
    --- 
    --- CLIENT-only
    ---@param len integer Ctor params length in bytes
    function NETABLE:Net_RecvInit(len)
        -- To be overriden
    end
end

--- Adds `CR.Net.Networkable` to `meta`.
--- Can be used on static objects w/o constructors.
--
--- @param meta CR.Class.Base
function CR.Net.MakeNetworkable(meta)
    table.Merge(meta, NETABLE)
end