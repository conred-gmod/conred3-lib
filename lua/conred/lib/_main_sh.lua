CR = CR or {}

--- filename: string
--- returns: bool
function CR.IsLuaFile(filename)
    return string.EndsWith(filename, ".lua")
end

--- filename: string
--- returns: "sv"|"cl"|"sh"|nil (nil when not a lua file)
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
    ["sh"] = Color(0, 196, 0)
    ["skip"] = Color(85,74,74)
}

--- filename: string
--- realm: nil (determine from filename) | "sv"|"cl"|"sh"
--- notify: bool|nil (if true, log the include)
--- returns: <whatever include(filename) returns>|nil (if include was not called, e.g. _cl.lua file on SERVER)
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
        
        if notify then MsgC(realm_colors[realm], filename) end
        
        return result
    end
end

--- Include all lua files in `path` (recursively, if `recurse` is set) 
---
--- path: string (directory path, including "/")
--- notify: bool|nil (if true, do logging)
--- recurse: bool|nil
function CR.IncludeDir(path, notify, recurse)
    local files, dirs = file.Find(path .. "*", "LUA")

    for _, fname in ipairs(files) do
        local file = path..fname

        if CR.IsLuaFile(file) then
            CR.IncludeFile(file, notify)
        else if notify then
            MsgC(realm_colors.skip, "[skipped] ",path)
        end
    end

    if not recurse then return end
    for _, dname in ipairs(dirs) do
        local dir = path..dname

        CR.IncludeDir(dir, notify, recurse)
    end
end

--- private
function CR.IncludeSmartSingle(entry, notify)
    local realm = CR.GetRealmFromFilename(entry)

    if realm ~= nil then
        CR.IncludeFile(entry, realm, notify)
    else if string.EndsWith(entry, "/*") then
        CR.IncludeDir(string.sub(entry, 1, -3), notify, false)
    end else if strings.EndsWith(entry, "/**") then
        CR.IncludeDir(string.sub(entry, 1, -4), notify, true)
    end else 
        ErrorNoHaltWithStack("Invalid smart include parameter ",entry)
    end
end

--- A more straightforward function for including lua files for the whole addon.
--- TODO: example (see below for now).
---
--- prefix: string
--- list: array(string)
--- notify: bool|nil (if true, do logging)
function CR.IncludeSmart(prefix, list, notify)
    for _, entry in ipairs(list) do
        CR.IncludeSmartSingle(prefix..entry, notify)
    end
end

CR.IncludeSmart("conred/lib/", {
    "util_sh.lua",
    "persist_sh.lua",

    "class/object_sh.lua",
    "class/new_delete_sh.lua",
    "class/registry_sh.lua"
}, true)

