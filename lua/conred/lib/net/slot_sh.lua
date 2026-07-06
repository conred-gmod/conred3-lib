local Class = CR.Class

local DOMAIN_MAX = 255
CR.Net.DOMAIN_BITS = 8

CR.Net.SLOT_BITS = 16
local SLOT_MAX = bit.lshift(1, CR.Net.SLOT_BITS) - 1

CR.Net.GEN_BITS = 12
CR.Net.GEN_MASK = bit.lshift(1, CR.Net.GEN_BITS) - 1

--- @class CR.Net.Slot: CR.Class.Constructable
--- @field Id integer Network id of the slot.
--- @field Obj CR.Net.Networkable? Networkable object in the slot.
--- @field Active boolean Can this slot be networked?
--- @field Gen integer Generation of the data in the slot. Increased when new object get assigned into slot.
--- 
--- @field _registry CR.Registry<CR.Net.Slot>
--- @field _domains CR.Net.Domain[]
--- @field _domainInit CR.Net.DomainInit?
--- @field _sendFilter CR.Net.SendFilter?
local Slot = Class.Define("CR.Net.Slot")
Class.MakeConstructable(Slot)
CR.Net.Slot = Slot


Slot._registry = CR.Registry:New("CR.Net.Slot._registry")
Slot._registry.MaxIndex = SLOT_MAX

function Slot:OnInit(id)
    self.Id = id
    self.Gen = 0
    self:Flush()

    self._registry:AddWithId(self, id)
end

if false then -- For annotations
    ---Creates and registers a slot
    ---@param id integer
    ---@return CR.Net.Slot
    function Slot:New(id)
        return Slot
    end
end

if SERVER then
    ---Finds or allocates an empty slot.
    ---
    ---SERVER-only.
    ---@return CR.Net.Slot
    function Slot.GetEmpty()
        for _, slot in pairs(Slot._registry.Objects) do
            if slot.Obj == nil then
                return slot
            end
        end

        return Slot:New(Slot._registry:NextIdx())
    end
end

function Slot:__tostring()
    local id = tostring(self.Id)
    local gen = tostring(self.Gen)
    local active = self.Active and "active" or "inactive"
    local object = self.Obj and tostring(self.Obj) or "[no object]"

    return "[slot #"..id.." (gen "..gen..", "..active..") for "..object.."]"
end

--- TODO: not how it works!!
function Slot:IsValid()
    return self.Active
end

---Sets slot's generation (w/ proper wraparound)
---@param gen integer
function Slot:SetGen(gen)
    self.Gen = bit.band(gen, CR.Net.GEN_MASK)
end

--- Resets slot's contents.
--- 
--- Deletes `.Obj` on CLIENT, if needed.
--- Increases generation if there was object.
function Slot:Flush()
    if IsValid(self.Obj) and CLIENT then
        local obj = self.Obj --[[@as CR.Class.Deletable]]
        if obj.Delete ~= nil then
            obj:Delete()
        else
            ErrorNoHalt("Attempt to flush ",self," with undeletable object.\n",
            "Server is giving wrong commands, pls report to devs. (This won't break anything by itself.)")
        end
    end

    if self.Obj ~= nil then
        self:SetGen(self.Gen + 1)
    end

    self.Obj = nil
    self.Active = false

    Class.TryDelete(self._domainInit)
    self._domainInit = nil

    for _, dom in ipairs(self._domains) do
        Class.TryDelete(dom)
    end
    self._domains = {}

    self._sendFilter = nil
end

---Adds a domain to slot.
---
---Can only be called before slot is activated.
---@param domain CR.Net.Domain
function Slot:AddDomain(domain)
    if self.Obj == nil then
        CR.Error(self, ": called AddDomain but there's no object assigned")
    end

    if self.Active then
        CR.Error(self, ": called AddDomain on active object (can't add domains to activated objects)")
    end

    if #self._domains == DOMAIN_MAX then
        CR.Error(self, ": called AddDomain, but there are too many domains already (at max=",DOMAIN_MAX,")")
    end

    local id = table.insert(self._domains, domain)
    domain:Attach(self, id)
end

---Assigns object to the slot and configures the slot based on the object.
---@param obj CR.Net.Networkable
function Slot:AssignAndConfigure(obj)
    assert(self.Obj == nil and not self.Active)

    self.Obj = obj
    local sf = obj.Net_SendFilter or CR.Net.SendFilter_Everyone
    self._domainInit = CR.Net.DomainInit:New(obj, sf)
    self._domainInit:Attach(self, 0)
    self._sendFilter = sf
end

---Marks slot as activated.
function Slot:Activate()
    if not IsValid(self.Obj) then
        CR.Error(self, ": called :Activate but object ",self.Obj," is invalid")
    end

    if self.Active then
        CR.Error(self, ": called :Activate but slot is already activated")
    end

    self.Active = true

    self._domainInit:Activate()
    for _, domain in ipairs(self._domains) do
        domain:Activate()
    end
end