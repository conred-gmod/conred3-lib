
local Class = CR.Class

local MSGNAME = "CR.Net.DomainMessage"

-------------------------------------

--- mixin CR.Net.Networkable
-- An object that supports networking between client and server.
--
--- :NetRecvInit(len: uint) optional -- called in net.Receive context, `self` is not valid yet. Read networked ctor params here.
--- :NetWriteInit() optional -- called in net.Start context. Write networked ctor params here.

local function netable_InitFromSlot(self, slot, init_len)
    assert(self.NetSlot == nil)
    self.NetSlot = slot

    if self.NetRecvInit then
        self:NetRecvInit(init_len)
    end

    self:Init()
end

local function netable_AddDomain(self, domain)
    self.NetSlot:DefineDomain(domain)

    return domain
end

local function netable_OnInit(self)
    -- TODO delay support?

    if SERVER then
        self.NetSlot:HandleInit()
    end
end

local function netable_OnDelete(self)
    if SERVER then
        self.NetSlot:HandleDelete()
    end
end

hook.Add("CR.Class.PostInit", "CR.Net.Networkable_Init", function(obj)
    if not obj.IsNetworkable then return end

    if SERVER then
        self.NetSlot:HandleInit()
    end
end)

--- Adds CR.Net.Networkable to `meta`.
-- Can be used on static objects w/o constructors.
--
--- meta: metatable(CR.Class.Base)
function CR.Net.MakeNetworkable(meta)
    self.IsNetworkable = true

    self.NetInitFromSlot = netable_InitFromSlot
    self.NetAddDomain = netable_AddDomain
end