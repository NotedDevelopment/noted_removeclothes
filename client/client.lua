local isMenuOpen   = false
local removingSlot = false
local targetSrvId  = nil
local targetPed    = nil

-- camera (orbit around target)
local undressCam = nil
local camYaw     = 0.0    -- degrees, around the target
local camPitch   = 35.0   -- degrees, elevation (positive = looking down)
local camRadius  = 2.2    -- meters from target

local FEMALE_HASH = GetHashKey('mp_f_freemode_01')

local SLOTS = {
    { id = 'hat',        label = 'Hat',            type = 'prop',      idx = 0,  boneHash = 31086 },
    { id = 'glasses',    label = 'Glasses',        type = 'prop',      idx = 1,  boneHash = 31086 },
    { id = 'earpiece',   label = 'Earpiece',       type = 'prop',      idx = 2,  boneHash = 31086 },
    { id = 'watch',      label = 'Watch',          type = 'prop',      idx = 6,  boneHash = 28422 },
    { id = 'bracelet',   label = 'Bracelet',       type = 'prop',      idx = 7,  boneHash = 60309 },
    { id = 'mask',       label = 'Mask',           type = 'component', idx = 1,  boneHash = 31086 },
    { id = 'hair',       label = 'Hair',           type = 'component', idx = 2,  boneHash = 31086 },
    { id = 'top',        label = 'Top',            type = 'component', idx = 11, boneHash = 24818 },
    { id = 'undershirt', label = 'Undershirt',     type = 'component', idx = 8,  boneHash = 24818 },
    { id = 'armor',      label = 'Body Armor',     type = 'component', idx = 9,  boneHash = 24818 },
    { id = 'neck',       label = 'Neck Accessory', type = 'component', idx = 7,  boneHash = 39317 },
    { id = 'bag',        label = 'Bag',            type = 'component', idx = 5,  boneHash = 24818 },
    { id = 'gloves',     label = 'Gloves',         type = 'component', idx = 3,  boneHash = 18905 },
    { id = 'decals',     label = 'Decals',         type = 'component', idx = 10, boneHash = 24818 },
    { id = 'pants',      label = 'Pants',          type = 'component', idx = 4,  boneHash = 11816 },
    { id = 'shoes',      label = 'Shoes',          type = 'component', idx = 6,  boneHash = 14201 },
}

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function slotById(id)
    for _, s in ipairs(SLOTS) do
        if s.id == id then return s end
    end
end

local function isMale(ped)
    return GetEntityModel(ped) ~= FEMALE_HASH
end

local function nakedDefaults(ped)
    return isMale(ped) and Config.NakedMale or Config.NakedFemale
end

local function isEquipped(ped, slot)
    if slot.type == 'prop' then
        return GetPedPropIndex(ped, slot.idx) ~= -1
    end
    local n = nakedDefaults(ped)[slot.idx]
    return GetPedDrawableVariation(ped, slot.idx) ~= (n and n.drawable or 0)
end

local function applyNaked(ped, slot)
    if slot.type == 'prop' then
        ClearPedProp(ped, slot.idx)
    else
        local n = nakedDefaults(ped)[slot.idx] or { drawable = 0, texture = 0 }
        SetPedComponentVariation(ped, slot.idx, n.drawable, n.texture, 2)
    end
end

--- Is the ped playing one of the qbx incapacitation clips (death, last stand,
--- handcuffed, surrender)?
local function isShowingVulnerableAnim(ped)
    for _, v in ipairs(Config.VulnerableAnims) do
        if IsEntityPlayingAnim(ped, v.dict, v.anim, 3) then return true end
    end
    return false
end

--- Cheap client-side pre-check: does this ped LOOK incapacitated? Used so the
--- initiator doesn't bother the server unless the target appears vulnerable.
--- The server callback is the authoritative confirmation.
local function looksVulnerable(ped)
    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then return true end
    if IsPedCuffed(ped) then return true end
    if IsPedRagdoll(ped) then return true end
    return isShowingVulnerableAnim(ped)
end

--- Am I (the LOCAL player) dead, downed, or cuffed? These are the "death
--- checks" that let someone strip the config free-slots off me without asking.
--- QBX.PlayerData is always us, so this is only valid for ourselves.
local function amIDownedOrCuffed()
    local meta = QBX.PlayerData and QBX.PlayerData.metadata
    if not meta then return false end
    return meta.isdead or meta.inlaststand or meta.ishandcuffed or false
end

local function buildSlotPayload(vulnerable, ped)
    local allowFree = vulnerable and not Config.AlwaysAsk
    local result = {}
    local hasLocked = false
    for _, s in ipairs(SLOTS) do
        local has  = isEquipped(ped, s)
        local free = has and allowFree and Config.FreeSlots[s.id] == true
        if has and not free then hasLocked = true end
        result[#result + 1] = {
            id    = s.id,
            label = s.label,
            has   = has,
            free  = free,
        }
    end
    return result, hasLocked
end

-- ─── camera ──────────────────────────────────────────────────────────────────

local function targetCenter()
    if not targetPed then return GetEntityCoords(PlayerPedId()) end
    local c = GetEntityCoords(targetPed)
    return vector3(c.x, c.y, c.z + 0.35)
end

local function updateCam()
    if not undressCam then return end
    local center = targetCenter()
    local yaw    = math.rad(camYaw)
    local pitch  = math.rad(camPitch)
    local cosP   = math.cos(pitch)
    local ox = camRadius * cosP * math.sin(yaw)
    local oy = camRadius * cosP * math.cos(yaw)
    local oz = camRadius * math.sin(pitch)
    SetCamCoord(undressCam, center.x + ox, center.y + oy, center.z + oz)
    PointCamAtCoord(undressCam, center.x, center.y, center.z)
end

local function createCam()
    undressCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(undressCam, 50.0)
    updateCam()
    RenderScriptCams(true, true, 400, true, true)
end

local function destroyCam()
    if undressCam then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(undressCam, false)
        undressCam = nil
    end
end

-- ─── world-label bone positions ──────────────────────────────────────────────

local function getBonePositions(ped)
    local out = {}
    for _, s in ipairs(SLOTS) do
        local bi = GetPedBoneIndex(ped, s.boneHash)
        local pos
        if bi ~= -1 then
            pos = GetWorldPositionOfEntityBone(ped, bi)
        else
            pos = GetEntityCoords(ped)
        end
        local ok, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z)
        out[s.id] = { x = sx, y = sy, visible = ok }
    end
    return out
end

-- ─── removal animation helpers ───────────────────────────────────────────────

--- Returns true if the target's head is at least Config.KneelHeightDiff below
--- ours (i.e. they're lying / on the ground), so we should kneel to undress them.
local function targetIsLow(tPed)
    local pPed   = PlayerPedId()
    local pBone  = GetPedBoneIndex(pPed, 31086)
    local tBone  = GetPedBoneIndex(tPed, 31086)
    local pHead  = pBone ~= -1 and GetWorldPositionOfEntityBone(pPed, pBone) or GetEntityCoords(pPed)
    local tHead  = tBone ~= -1 and GetWorldPositionOfEntityBone(tPed, tBone) or GetEntityCoords(tPed)
    return (pHead.z - tHead.z) >= Config.KneelHeightDiff
end

-- ─── menu open / close ───────────────────────────────────────────────────────

local function openMenu(srvId, tPed, vulnerable)
    if isMenuOpen then return end
    isMenuOpen  = true
    targetSrvId = srvId
    targetPed   = tPed
    camYaw      = GetEntityHeading(tPed) + 180.0
    camPitch    = 35.0
    camRadius   = 2.2

    createCam()

    local slots, hasLocked = buildSlotPayload(vulnerable, tPed)
    SendNUIMessage({ action = 'open', slots = slots, hasLocked = hasLocked })
    SetNuiFocus(true, true)

    -- render loop: camera + world-label positions
    CreateThread(function()
        while isMenuOpen do
            DisableAllControlActions(0)
            updateCam()
            SendNUIMessage({
                action    = 'updatePositions',
                positions = getBonePositions(targetPed),
            })
            Wait(0)
        end
    end)

    -- periodic distance watcher (separate, slower cadence)
    CreateThread(function()
        while isMenuOpen do
            Wait(Config.MenuDistanceCheckInterval)
            if not isMenuOpen then break end
            local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetPed))
            if dist > Config.MenuMaxDistance then
                lib.notify({ title = 'Too far away', description = 'They moved away.', type = 'error' })
                closeMenu()
                break
            end
        end
    end)
end

function closeMenu()
    if not isMenuOpen then return end
    isMenuOpen   = false
    targetSrvId  = nil
    targetPed    = nil
    removingSlot = false

    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    destroyCam()
end

-- ─── NUI callbacks (initiator) ───────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({})
end)

-- Mouse-orbit: right-drag deltas from the browser
RegisterNUICallback('orbitCamera', function(data, cb)
    camYaw   = camYaw - (data.dx or 0) * 0.25
    camPitch = math.max(-20.0, math.min(85.0, camPitch + (data.dy or 0) * 0.25))
    cb({})
end)

-- Scroll zoom
RegisterNUICallback('zoomCamera', function(data, cb)
    camRadius = math.max(1.2, math.min(5.0, camRadius + (data.delta or 0) * 0.0015))
    cb({})
end)

RegisterNUICallback('removeSlot', function(data, cb)
    if not isMenuOpen or removingSlot or not targetPed then cb({}); return end
    local slot = slotById(data.id)
    if not slot then cb({}); return end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetPed)) > Config.MaxDistance then
        lib.notify({ title = 'Too far away', type = 'error' })
        cb({})
        return
    end

    -- Kneel + mechanic fidget if they're on the ground, otherwise a standing
    -- uncuff-style fiddle.
    local anim = targetIsLow(targetPed) and Config.Anims.kneel or Config.Anims.standing

    removingSlot = true
    local ok = lib.progressBar({
        duration     = Config.RemoveClothingDuration,
        label        = ('Removing %s...'):format(slot.label),
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = anim.dict, clip = anim.anim, flag = anim.flag },
    })

    if ok then
        if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetPed)) <= Config.MaxDistance then
            -- The target's client authorizes & applies (approval or vulnerable),
            -- then reports back via client:stripResult.
            TriggerServerEvent('noted_removeclothes:server:tryStrip', targetSrvId, slot.id)
        else
            lib.notify({ title = 'Too far away', type = 'error' })
        end
    end

    removingSlot = false
    cb({})
end)

-- Result of a strip attempt comes back from the target's client (via server)
RegisterNetEvent('noted_removeclothes:client:stripResult', function(slotId, success)
    if not isMenuOpen then return end
    if success then
        SendNUIMessage({ action = 'slotRemoved', id = slotId })
    else
        local slot = slotById(slotId)
        lib.notify({ title = 'Denied', description = ('You can\'t remove their %s.'):format(slot and slot.label or 'item'), type = 'error' })
    end
end)

-- Request permission to remove the locked slots
RegisterNUICallback('requestPermission', function(_, cb)
    if not isMenuOpen then cb({}); return end
    TriggerServerEvent('noted_removeclothes:server:requestPermission', targetSrvId)
    lib.notify({ title = 'Permission requested', description = 'Waiting for a response...', type = 'inform' })
    cb({})
end)

-- Initiator receives the verdict
RegisterNetEvent('noted_removeclothes:client:permissionResult', function(accepted)
    if not isMenuOpen then return end
    if accepted then
        SendNUIMessage({ action = 'grantAll' })
        lib.notify({ title = 'Permission granted', type = 'success' })
    else
        lib.notify({ title = 'Permission denied', type = 'error' })
    end
end)

-- ─── target-side: approvals + strip authorization ────────────────────────────

local requestActive = false
local approvals = {}  -- [initiatorSrvId] = expiry (GetGameTimer ms)

local function hasApproval(srvId)
    local exp = approvals[srvId]
    return exp ~= nil and GetGameTimer() < exp
end

local function grantApproval(srvId)
    approvals[srvId] = GetGameTimer() + Config.ApprovalDuration
end

-- Someone is trying to strip a slot off us. We are authoritative for our own
-- approvals and our own death/cuff state, so we decide here.
RegisterNetEvent('noted_removeclothes:client:validateStrip', function(initiatorSrvId, slotId)
    local slot = slotById(slotId)
    if not slot then return end

    local allowed = false
    if hasApproval(initiatorSrvId) then
        allowed = true
    elseif not Config.AlwaysAsk and Config.FreeSlots[slotId]
        and (amIDownedOrCuffed() or isShowingVulnerableAnim(PlayerPedId())) then
        allowed = true
    end

    if allowed then
        applyNaked(PlayerPedId(), slot)  -- networked to everyone, incl. the initiator
    end
    TriggerServerEvent('noted_removeclothes:server:stripApplied', initiatorSrvId, slotId, allowed)
end)

-- Server-sourced id of whoever is currently asking us (trusted, not from NUI).
local pendingRequestFrom = nil

RegisterNetEvent('noted_removeclothes:client:permissionRequest', function(initiatorSrvId, initiatorName)
    if requestActive then
        TriggerServerEvent('noted_removeclothes:server:respondPermission', initiatorSrvId, false)
        return
    end
    requestActive = true
    pendingRequestFrom = initiatorSrvId

    SendNUIMessage({ action = 'showRequest', initiator = initiatorName or 'Someone' })
    SetNuiFocus(true, false)  -- keyboard only, leave mouse to the game

    -- auto-deny after 12s
    SetTimeout(12000, function()
        if requestActive then
            requestActive = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'hideRequest' })
            TriggerServerEvent('noted_removeclothes:server:respondPermission', initiatorSrvId, false)
            pendingRequestFrom = nil
        end
    end)
end)

RegisterNUICallback('respondPermission', function(data, cb)
    requestActive = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideRequest' })

    local initiatorSrvId = pendingRequestFrom
    pendingRequestFrom = nil
    if not initiatorSrvId then cb({}); return end

    if data.accepted == true then
        grantApproval(initiatorSrvId)  -- cache so future strips skip the prompt
    end
    TriggerServerEvent('noted_removeclothes:server:respondPermission', initiatorSrvId, data.accepted == true)
    cb({})
end)

-- ─── visual removal applied to the target's own ped ──────────────────────────

RegisterNetEvent('noted_removeclothes:client:applyRemoval', function(slotId)
    local slot = slotById(slotId)
    if slot then applyNaked(PlayerPedId(), slot) end
end)

RegisterNetEvent('noted_removeclothes:client:shoesStolen', function(thiefName)
    lib.notify({ title = 'Shoes stolen!', description = (thiefName or 'Someone') .. ' took your shoes.', type = 'error' })
end)

-- ─── shoe stealing ───────────────────────────────────────────────────────────

RegisterNetEvent('noted_removeclothes:client:doShoeSkillCheck', function(thiefSrvId)
    -- Can't defend our shoes if we're downed / cuffed / surrendering.
    if isShowingVulnerableAnim(PlayerPedId()) then
        TriggerServerEvent('noted_removeclothes:server:shoeSkillResult', thiefSrvId, false)
        return
    end
    lib.notify({ title = 'Watch out!', description = 'Someone is going for your shoes!', type = 'warning', duration = 2500 })
    local passed = lib.skillCheck({ 'easy', 'easy' }, { 'w', 'a', 's', 'd' })
    TriggerServerEvent('noted_removeclothes:server:shoeSkillResult', thiefSrvId, passed)
end)

RegisterNetEvent('noted_removeclothes:client:shoesSuccess', function()
    lib.notify({ title = 'Shoes snagged!', description = 'You grabbed their shoes.', type = 'success' })
end)

RegisterNetEvent('noted_removeclothes:client:shoesKept', function()
    lib.notify({ title = 'Failed', description = 'They kept their shoes.', type = 'error' })
end)

local function stealShoes(tPed, tSrvId)
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(tPed)) > Config.MaxDistance then
        lib.notify({ title = 'Too far away', type = 'error' })
        return
    end

    local ok = lib.progressBar({
        duration     = Config.StealShoesDuration,
        label        = 'Untying their laces...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = false, car = true, combat = true },
    })
    if not ok then return end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(tPed)) > Config.MaxDistance then
        lib.notify({ title = 'Too far away', type = 'error' })
        return
    end

    TriggerServerEvent('noted_removeclothes:server:stealShoes', tSrvId)
end

-- ─── ox_target ───────────────────────────────────────────────────────────────

exports.ox_target:addGlobalPlayer({
    {
        name     = 'noted_undress',
        label    = 'Undress Player',
        icon     = 'fa-solid fa-shirt',
        distance = Config.MaxDistance,
        onSelect = function(data)
            local tPlayer = NetworkGetPlayerIndexFromPed(data.entity)
            if tPlayer == -1 then return end
            local tSrvId = GetPlayerServerId(tPlayer)
            if tSrvId == GetPlayerServerId(PlayerId()) then return end

            -- Vulnerability is judged purely from the target's animations,
            -- client-side. The target re-validates before anything is removed.
            local vulnerable = looksVulnerable(data.entity)
            openMenu(tSrvId, data.entity, vulnerable)
        end,
    },
    {
        name     = 'noted_steal_shoes',
        label    = 'Steal Shoes',
        icon     = 'fa-solid fa-shoe-prints',
        distance = Config.MaxDistance,
        onSelect = function(data)
            local tPlayer = NetworkGetPlayerIndexFromPed(data.entity)
            if tPlayer == -1 then return end
            local tSrvId = GetPlayerServerId(tPlayer)
            if tSrvId == GetPlayerServerId(PlayerId()) then return end
            stealShoes(data.entity, tSrvId)
        end,
    },
})
