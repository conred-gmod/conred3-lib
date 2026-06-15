local function UnlockPersistData()
    __cr_persistdata_unlocked = true

    local HOOK_NAME = "CR.PersistTableLock"

    hook.Add("Tick", HOOK_NAME, function()
        __cr_persistdata_unlocked = false
        hook.Remove("Tick", HOOK_NAME)
    end)
end

__cr_persistdata = __cr_persistdata or {}

UnlockPersistData()
hook.Add("OnReloaded", "CR.PersistTableUnlock", UnlockPersistData)


function CR.GetPersistedTable(name, default)
    if __cr_persistdata[name] ~= nil then
        return __cr_persistdata[name]
    else
        assert(__cr_persistdata_unlocked, "Function called in wrong time (not before first game tick)")
        __cr_persistdata[name] = default
        return default
    end
end

concommand.Add("cr_persisttable_clear", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then
        return
    end

    UnlockPersistData()
    for _, tbl in pairs(__cr_persistdata) do
        table.Empty(tbl)
    end

    print("Cleared persist table")
end)