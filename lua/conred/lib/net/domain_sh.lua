local Class = CR.Class

--- An independent part of a networkable object.
--- @class CR.Net.Domain: CR.Class.Constructable, CR.Class.Deletable
--- @field protected _send fun()?
--- @field protected _recv fun(ply: Player?, len:integer)?
--- @field protected _sendFilter CR.Net.SendFilter?
--- @field protected _recvFilter (fun(Player): boolean)?
local Domain = Class.Define("CR.Net.Domain")
CR.Net.Domain = Domain

Class.MakeConstructable(Domain)
Class.MakeDeletable(Domain)

function Domain:OnInit(params)
    self._sendFilter = params.SendFilter
    self._recvFilter = params.RecvFilter
end

--- Called in `net.Recieve` context. Read netmessage sent to domain here.
--- @param len integer Length of message to domain in bits (excluding aux info like domain ID, slot ID and the like.)
--- @param ply Player? On SERVER, player who sent this message. On CLIENT, nil.
function Domain:Net_RecvData(len, ply)
    assert(false, "Implement me!")
end

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