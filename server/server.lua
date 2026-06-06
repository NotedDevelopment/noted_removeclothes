local pendingShoeChecks = {}  -- [targetSrvId] = thiefSrvId

local function getPlayerDist(a, b)
    local pa = GetEntityCoords(GetPlayerPed(a))
    local pb = GetEntityCoords(GetPlayerPed(b))
    return #(pa - pb)
end

--- Dead or in last stand, via QBox player management. Edit if your server
--- tracks death differently.
local function getDeathState(tgtId)
    local player = exports.qbx_core:GetPlayer(tgtId)
    if not player then return false end
    return player.PlayerData.metadata.isdead
        or player.PlayerData.metadata.inlaststand
        or false
end

-- Initiator wants to strip a slot. Relay to the target, who authorizes it
-- (their approval cache / their own death-cuff state) and applies it.
RegisterNetEvent('noted_removeclothes:server:tryStrip', function(targetSrvId, slotId)
    local src = source
    if not GetPlayerPed(targetSrvId) then return end
    if getPlayerDist(src, targetSrvId) > Config.MaxDistance * 2 then return end
    TriggerClientEvent('noted_removeclothes:client:validateStrip', targetSrvId, src, slotId)
end)

-- Target reports the outcome; relay back to the initiator for their menu.
RegisterNetEvent('noted_removeclothes:server:stripApplied', function(initiatorSrvId, slotId, success)
    if not GetPlayerPed(initiatorSrvId) then return end
    TriggerClientEvent('noted_removeclothes:client:stripResult', initiatorSrvId, slotId, success == true)
end)

-- ─── permission requests ─────────────────────────────────────────────────────

RegisterNetEvent('noted_removeclothes:server:requestPermission', function(targetSrvId)
    local src = source
    if not GetPlayerPed(targetSrvId) then return end
    if getPlayerDist(src, targetSrvId) > Config.MaxDistance * 2 then return end
    TriggerClientEvent('noted_removeclothes:client:permissionRequest', targetSrvId, src, GetPlayerName(src))
end)

RegisterNetEvent('noted_removeclothes:server:respondPermission', function(initiatorSrvId, accepted)
    if not GetPlayerPed(initiatorSrvId) then return end
    TriggerClientEvent('noted_removeclothes:client:permissionResult', initiatorSrvId, accepted == true)
end)

-- ─── shoe stealing ───────────────────────────────────────────────────────────

RegisterNetEvent('noted_removeclothes:server:stealShoes', function(targetSrvId)
    local src = source
    if not GetPlayerPed(targetSrvId) then return end
    if getPlayerDist(src, targetSrvId) > Config.MaxDistance * 2 then return end

    if getDeathState(targetSrvId) then
        exports.ox_inventory:AddItem(src, Config.ShoeItem, 1)
        TriggerClientEvent('noted_removeclothes:client:applyRemoval', targetSrvId, 'shoes')
        TriggerClientEvent('noted_removeclothes:client:shoesStolen', targetSrvId, GetPlayerName(src))
        TriggerClientEvent('noted_removeclothes:client:shoesSuccess', src)
    else
        -- Not downed: target defends with a skill check (or auto-loses if surrendering)
        pendingShoeChecks[targetSrvId] = src
        TriggerClientEvent('noted_removeclothes:client:doShoeSkillCheck', targetSrvId, src)
    end
end)

RegisterNetEvent('noted_removeclothes:server:shoeSkillResult', function(thiefSrvId, passed)
    local src = source  -- the target who defended
    if pendingShoeChecks[src] ~= thiefSrvId then return end
    pendingShoeChecks[src] = nil

    if not GetPlayerPed(thiefSrvId) then return end
    if getPlayerDist(src, thiefSrvId) > Config.MaxDistance * 2 then return end

    if passed then
        TriggerClientEvent('noted_removeclothes:client:shoesKept', thiefSrvId)
    else
        exports.ox_inventory:AddItem(thiefSrvId, Config.ShoeItem, 1)
        TriggerClientEvent('noted_removeclothes:client:applyRemoval', src, 'shoes')
        TriggerClientEvent('noted_removeclothes:client:shoesStolen', src, GetPlayerName(thiefSrvId))
        TriggerClientEvent('noted_removeclothes:client:shoesSuccess', thiefSrvId)
    end
end)
