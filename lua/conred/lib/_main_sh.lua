CR = CR or {}

--- @param filename string
--- @return boolean
function CR.IsLuaFile(filename)
    return string.EndsWith(filename, ".lua")
end

--- @param filename string
--- @return nil|"sv"|"cl"|"sh" # nil when not a lua file
function CR.GetRealmFromFilename(filename)
    if not CR.IsLuaFile(filename) then
        return nil
    elseif string.EndsWith(filename, "_sv.lua") then
        return "sv"
    elseif string.EndsWith(filename, "_cl.lua") then
        return "cl"
    end

    -- xxx_sh.lua goes there
    return "sh"
end

local realm_colors = {
    ["sv"] = Color(0, 0, 201),
    ["cl"] = Color(223, 223, 35),
    ["sh"] = Color(0, 196, 0),
    ["skip"] = Color(85,74,74)
}

---@param filename string
---@param realm nil|"sv"|"cl"|"sh" nil == determine from filename
---@param notify boolean|nil if true, log the include
---@return any|nil # Returns whatever `include(filename)` returns. Returns null if include was not called, e.g. `_cl.lua` file on SERVER.
function CR.IncludeFile(filename, realm, notify)
    realm = realm or CR.GetRealmFromFilename(filename)
    assert(realm ~= nil, "Attempt to include non-lua file")

    if realm ~= "sv" and SERVER then
        AddCSLuaFile(filename)
    end

    if  (realm == "sv" and SERVER) or
        (realm == "cl" and CLIENT) or
        (realm == "sh")
    then
        local result = include(filename)

        if notify then MsgC(realm_colors[realm], filename, "\n") end

        return result
    end
end

--- Include all lua files in `path` (recursively, if `recurse` is set)
---
--- @param path string directory path, including "/"
--- @param notify boolean|nil if true, do logging
--- @param recurse boolean|nil
function CR.IncludeDir(path, notify, recurse)
    local files, dirs = file.Find(path .. "*", "LUA")

    for _, fname in ipairs(files) do
        local file = path..fname

        if CR.IsLuaFile(file) then
            CR.IncludeFile(file, nil, notify)
        elseif notify then
            MsgC(realm_colors.skip, "[skipped] ",path, "\n")
        end
    end

    if not recurse then return end
    for _, dname in ipairs(dirs) do
        local dir = path..dname

        CR.IncludeDir(dir, notify, recurse)
    end
end

--- **Private function.**
function CR.IncludeSmartSingle(entry, notify)
    local realm = CR.GetRealmFromFilename(entry)

    if realm ~= nil then
        CR.IncludeFile(entry, realm, notify)
    elseif string.EndsWith(entry, "/*") then
        CR.IncludeDir(string.sub(entry, 1, -3), notify, false)
    elseif string.EndsWith(entry, "/**") then
        CR.IncludeDir(string.sub(entry, 1, -4), notify, true)
    else
        ErrorNoHaltWithStack("Invalid smart include parameter ",entry)
    end
end

--- A more straightforward function for including lua files for the whole addon. <br>
--- TODO: example (see below for now).
---
--- @param prefix string
--- @param list string[]
--- @param notify boolean|nil if true, do logging
function CR.IncludeSmart(prefix, list, notify)
    for _, entry in ipairs(list) do
        CR.IncludeSmartSingle(prefix..entry, notify)
    end
end

CR.IncludeSmart("conred/lib/", {
    "thirdparty_sh.lua",
    "util_sh.lua",
}, true)

CR.PrepareNamespace(CR, {
    Class = {},
    Net = {}
})

CR.IncludeSmart("conred/lib/", {
    "persist_sh.lua",

    "class/object_sh.lua",
    "class/new_delete_sh.lua",
    "class/registry_sh.lua",
    "semaphore_callback_sh.lua",

    "net/sendfilter_sv.lua",
    "net/domain_sh.lua",
    "net/slot_sh.lua",
    "net/recv_buffer_sh.lua",
    "net/slot_txrx_sh.lua",
    "net/networkable_sh.lua"
}, true)

