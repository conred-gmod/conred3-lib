local Class = CR.Class
local Domain = CR.Net.Domain

--- @class CR.Net.DomainEvent: CR.Net.Domain
local DomEvent = Class.Define("CR.Net.DomainEvent", Domain)
CR.Net.DomainEvent = DomEvent


--- @class CR.Net.DomainVar: CR.Net.Domain
local DomVar = Class.Define("CR.Net.DomainVar", Domain)
CR.Net.DomainVar = DomVar

--- @class CR.Net.DomainInit: CR.Net.DomainVar
local DomInit = Class.Define("CR.Net.DomainInit", DomVar)
CR.Net.DomainInit = DomInit

if false then -- For annotations
    ---Makes new domain
    ---
    --- `params.Send`: needed only on SERVER, `net.Start` context. <br>
    --- `params.Recv`: needed only on CLIENT, `net.Receive` context, `len`: userdata length in bits . <br>
    --- `params.SendFilter`: needed only on SERVER
    ---@param params { Send: fun()?, Recv: fun(len: integer)?, SendFilter: CR.Net.SendFilter?}
    ---@return CR.Net.DomainInit
    function DomInit:New(params)
        return DomInit
    end
end