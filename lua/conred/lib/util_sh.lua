--- Like `table.concat`, but calls `CR.ToString` on each argument.
---
--- varargs: ...(any|nil)
--- result: string
function table.ConcatToString(...)
    local parts = {...}
    for i = 1, select("#", ...) do
        parts[i] = CR.ToString(parts[i])
    end

    return table.concat(parts, "")
end

--- Like `ErrorNoHalt`, but it halts. (`Error` is broken.)
---
--- msg: ...(any|nil)
function CR.Error(...)
    error(table.ConcatToString(...), 2)
end

--- Like `tostring`, but it returns "nil" for `nil` and prints down tables without tostring
---
--- val: any|nil
--- pretty_print: bool|nil (if true, tables will be tabulated and not on a single string)
function CR.ToString(val, pretty_print)
    pretty_print = pretty_print or false

    if val == nil then
        return "nil"
    elseif istable(val) then
        local meta = debug.getmetatable(val)
        if meta == nil or meta.__tostring == nil then
            return table.ToString(val, nil, pretty_print)
        end
    end

    return tostring(val)
end

--- Generates stub namespace tables, if they don't exist.
--- Use `SERVER and {}` for server-only namespaces, `CLIENT and {}` for client-only ones.
--- Example:
--- CR.PrepareNamespace(CR, {Object = {Net = {}}, DatabaseSV = SERVER and {}})
---
--- nspace: table
--- template: table
function CR.PrepareNamespace(nspace, template)
    assert(istable(nspace))
    assert(istable(template))

    for k, v in pairs(template) do
        if nspace[k] == nil and istable(v) then
            nspace[k] = {}
            CR.PrepareNamespace(nspace[k], v)
        end
    end

    return nspace
end