

--- A mixin for object that supports networking between client and server.
--- 
--- Supports static classes as well.
---
--- @class CR.Net.Networkable: CR.Class.Base
--- @field IsNetworkable true
--- @field Net_Slot CR.Net.Slot
--- 
--- @field Net_SendFilter CR.Net.SendFilter? Optional sendfilter used for this object. Set it in `:Net_Setup`.
local NETABLE = {}

NETABLE.IsNetworkable = true

--- Adds domain to the networkable object. Max 255 domains per object. 
--- 
--- Call me in `:Net_Setup` only.
--- @param domain CR.Net.Domain
--- @return CR.Net.Domain # `= domain`
function NETABLE:Net_AddDomain(domain)
    self.Net_Slot:AddDomain(domain)

    return domain
end

--- Called before :OnInit, implement it and configure net stuff here.
function NETABLE:Net_Setup()
    assert(false, "Implement me!")
end

--- Marks the static networkable class as initialized, activates networking.
--- 
--- Will error if used on non-static object.
function NETABLE:StaticInitialized()
    local maybe_ctorable = self --[[@as CR.Class.Constructable]]
    if maybe_ctorable.Init ~= nil or maybe_ctorable.New ~= nil or maybe_ctorable.Construct ~= nil then
        CR.Error("Attempt to use :Net_StaticInitialized on non-static class ",maybe_ctorable)
    end

    CR.Net.Slot._StaticInitialized(self)
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
    assert(isbool(meta.IsStatic), "meta has no boolean .IsStatic\n"..
        "Use CR.Class.MakeConstructable (or CR.Net.MakeInstanceNetworkable) or CR.Class.MakeStaticInitable (or CR.Net.MakeStaticNetworkable)")

    table.Merge(meta, NETABLE)

    if meta.IsStatic and CLIENT then
        meta.__delayStaticInit = true
    end
end

--- Makes metatable into (non-static) networkable class.
--- 
--- Adds `CR.Class.Constructable`, `CR.Class.Deletable` and `CR.Net.Networkable`.
--- 
--- @param meta CR.Net.InstanceNetworkable
function CR.Net.MakeInstanceNetworkable(meta)
    CR.Class.MakeConstructable(meta)
    CR.Class.MakeDeletable(meta)
    CR.Net.MakeNetworkable(meta)
end

--- Makes metatable into static networkable class
--- 
--- Adds `CR.Class.StaticInitable` and `CR.Net.Networkable`.
--- 
--- @param meta CR.Net.StaticNetworkable
function CR.Net.MakeStaticNetworkable(meta)
    CR.Class.MakeStaticInitable(meta)

    CR.Net.MakeNetworkable(meta)
end