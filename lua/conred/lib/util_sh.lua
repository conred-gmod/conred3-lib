--- Like `table.concat`, but calls `CR.ToString` on each argument.<br>
--- You can supply `nil`s:<br>
--- `table.ConcatToString(nil," is ",nil) == "nil is nil"`
---
--- @param ... any|nil
--- @return string
function table.ConcatToString(...)
    local parts = {...}
    for i = 1, select("#", ...) do
        parts[i] = CR.ToString(parts[i])
    end

    return table.concat(parts, "")
end

--- Like `#tbl`, but handles non-sequential tables correctly.
--- @param tbl table
--- @return integer # Sequential element count
function table.SeqCount(tbl)
    local i = 0

    repeat
        i = i + 1
    until tbl[i] == nil

    return i - 1
end

--- Like `table.HasValue(arr, value)`, but for arrays and faster.
--- @param arr any[]
--- @param value any
--- @return boolean has_value
--- @return integer? first_value_index
function table.SeqHasValue(arr, value)
    for i, value in ipairs(arr) do
        if arr == value then return true, i end
    end

    return false, nil
end

--- Removes value from array by moving the last value into now-empty slot.
--- 
--- Does not preserves order.
--- @param tbl table Array
--- @param value any Value to be removed
--- @return integer? Index where the value used to be
function table.RemoveFastByValue(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            tbl[i] = tbl[#tbl]
            tbl[#tbl] = nil

            return i
        end
    end
end

--- Like `ErrorNoHalt`, but it halts. (`Error` is broken.)
---
--- @param ... any|nil
function CR.Error(...)
    error(table.ConcatToString(...), 2)
end

--- Like `tostring`, but it returns "nil" for `nil` and prints down tables without tostring
---
--- @param val any|nil
--- @param pretty_print boolean|nil if true, tables will be tabulated and not on a single string
--- @return string
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
--- @param nspace table
--- @param template table
--- @return table `= nspace`
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