local function UnlockPersistData()
    __CR_persistdata_unlocked = true

    local HOOK_NAME = "CR.PersistTableLock"

    hook.Add("Tick", HOOK_NAME, function()
        __CR_persistdata_unlocked = false
        hook.Remove("Tick", HOOK_NAME)
    end)
end

--- @type { [string]: table }
__CR_persistdata = __CR_persistdata or {}

UnlockPersistData()
hook.Add("OnReloaded", "CR.PersistTableUnlock", UnlockPersistData)

--- Returns a table that is persisted between hot reloads.
--
--- @param name string table name (for hot reload persistance needs)
--- @param default table|nil a default value (new empty table if nil)
--- @return table
function CR.GetPersistedTable(name, default)
    if default == nil then default = {} end

    if __CR_persistdata[name] ~= nil then
        return __CR_persistdata[name]
    else
        assert(__CR_persistdata_unlocked, "Function called in wrong time (not before first game tick)")
        __CR_persistdata[name] = default
        return default
    end
end

concommand.Add("cr_persisttable_clear", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then
        return
    end

    UnlockPersistData()
    for _, tbl in pairs(__CR_persistdata) do
        table.Empty(tbl)
    end

    print("Cleared persist table")
end)