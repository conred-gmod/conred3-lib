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
