local debugEnabled = Config.Debug == true
local gameplayEnabled = true
local gameplayActive = false
local lastEventAt = {}
local lastVehicleSpeed = 0.0
local wasFiring = false
local fireStartedAt = 0
local lastFirePulseAt = 0
local fireBurst = false
local receivingPartnerEvent = false
local wasMelee = false
local wasFalling = false
local wasRagdoll = false

local function log(message)
    if debugEnabled then
        print(('[xToys Self Control:DEBUG] %s'):format(tostring(message)))
    end
end

local function notify(message)
    SendNUIMessage({ type = 'toast', message = message })
end

local function eventReady(key, cooldown)
    local now = GetGameTimer()
    local waitMs = cooldown or Config.SelfControl.EventCooldownMilliseconds
    if lastEventAt[key] and now - lastEventAt[key] < waitMs then
        return false
    end
    lastEventAt[key] = now
    return true
end

local function pulse(intensity, duration, source)
    if not gameplayEnabled then return end

    intensity = math.max(0, math.min(Config.MaxIntensity, tonumber(intensity) or 0))
    duration = math.max(1, math.min(Config.SelfControl.MaxDurationSeconds, tonumber(duration) or 1))
    if intensity <= 0 then return end

    gameplayActive = true
    if not receivingPartnerEvent then
        TriggerServerEvent('xtoys:selfControlSharePulse', intensity, duration, tostring(source or 'gameplay'))
    end
    log(('Pulse [%s]: intensity=%d duration=%s'):format(source or 'gameplay', intensity, tostring(duration)))
    SendNUIMessage({
        type = 'xtoysCommand',
        action = Config.XToysActions.SetIntensity,
        intensity = intensity,
        duration = duration
    })
end

local function stopToy(force, fromPartner)
    if not fromPartner then TriggerServerEvent('xtoys:selfControlShareStop') end
    if gameplayActive or force then
        SendNUIMessage({ type = 'xtoysStop', action = Config.XToysActions.Stop })
        gameplayActive = false
        log('Stop sent.')
    end
end

local function openMenu()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
end

local function emergencyStop()
    gameplayEnabled = false
    stopToy(true)
    SendNUIMessage({ type = 'enabledState', enabled = false })
    notify('Emergency stop sent. Triggers paused. Re-enable them in the menu or use /xtoysdebug resume.')
end

local function connectFromCommand(webhookId)
    webhookId = tostring(webhookId or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if webhookId == '' then
        notify('Usage: /xtoysconnect YOUR_PRIVATE_WEBHOOK_ID')
        return
    end
    SendNUIMessage({ type = 'connectWebhook', webhookId = webhookId })
end

RegisterCommand(Config.OpenCommand, openMenu, false)

-- Partner sharing is opt-in: invite with /xtoyspartner SERVER_ID, then the
-- other player accepts with /xtoyspartneraccept SERVER_ID.
RegisterCommand('xtoyspartner', function(_, args)
    local target = tonumber(args[1])
    if not target then notify('Usage: /xtoyspartner SERVER_ID') return end
    TriggerServerEvent('xtoys:selfControlPartnerInvite', target)
end, false)
RegisterCommand('xtoyspartneraccept', function(_, args)
    local inviter = tonumber(args[1])
    if not inviter then notify('Usage: /xtoyspartneraccept SERVER_ID') return end
    TriggerServerEvent('xtoys:selfControlPartnerAccept', inviter)
end, false)
RegisterCommand('xtoyspartnerdecline', function(_, args)
    local inviter = tonumber(args[1])
    if not inviter then notify('Usage: /xtoyspartnerdecline SERVER_ID') return end
    TriggerServerEvent('xtoys:selfControlPartnerDecline', inviter)
end, false)
RegisterCommand('xtoyspartnerstop', function()
    TriggerServerEvent('xtoys:selfControlPartnerEnd')
end, false)

RegisterNetEvent('xtoys:selfControlPartnerNotice', function(message)
    notify(message)
end)
RegisterNetEvent('xtoys:selfControlPartnerPulse', function(intensity, duration, eventSource)
    if not gameplayEnabled then return end
    receivingPartnerEvent = true
    pulse(intensity, duration, 'partner: ' .. tostring(eventSource or 'gameplay'))
    receivingPartnerEvent = false
end)
RegisterNetEvent('xtoys:selfControlPartnerStop', function()
    stopToy(true, true)
end)
RegisterCommand('+xtoys_menu', openMenu, false)
RegisterCommand('-xtoys_menu', function() end, false)
RegisterKeyMapping('+xtoys_menu', 'Open xToys Self Control menu', 'keyboard', 'F7')

RegisterCommand(Config.StopCommand, emergencyStop, false)
RegisterCommand('xtoys_emergency_key', emergencyStop, false)
RegisterKeyMapping('xtoys_emergency_key', 'xToys emergency stop (pause gameplay triggers)', 'keyboard', 'F8')

RegisterCommand(Config.ConnectCommand, function(_, args)
    connectFromCommand(table.concat(args, ' '))
end, false)

RegisterCommand(Config.DebugCommand, function(_, args)
    local mode = (args[1] or 'status'):lower()
    if mode == 'on' then
        debugEnabled = true
        notify('Debug logging enabled. Check F8.')
        log('Debug logging enabled.')
    elseif mode == 'off' then
        debugEnabled = false
        notify('Debug logging disabled.')
    elseif mode == 'resume' then
        gameplayEnabled = true
        notify('Gameplay triggers resumed.')
        SendNUIMessage({ type = 'enabledState', enabled = true })
    else
        notify(('Debug: %s | Gameplay: %s'):format(debugEnabled and 'ON' or 'OFF', gameplayEnabled and 'ON' or 'PAUSED'))
    end
end, false)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('setEnabled', function(data, cb)
    gameplayEnabled = data.enabled == true
    if not gameplayEnabled then stopToy(true) end
    SendNUIMessage({ type = 'enabledState', enabled = gameplayEnabled })
    cb({ ok = true })
end)

RegisterNUICallback('emergencyStop', function(_, cb)
    emergencyStop()
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        Wait(Config.SelfControl.PollMilliseconds)

        if not gameplayEnabled then
            wasFiring = false
            wasMelee = false
            wasFalling = false
            wasRagdoll = false
            lastVehicleSpeed = 0.0
        else
            local ped = PlayerPedId()
            if ped ~= 0 and DoesEntityExist(ped) then
                local now = GetGameTimer()
                local firing = IsPedShooting(ped)

                if firing then
                    if not wasFiring then
                        fireStartedAt = now
                        fireBurst = false
                        pulse(Config.SelfControl.ContinuousFireIntensity,
                            math.random(Config.SelfControl.ShotMinSeconds, Config.SelfControl.ShotMaxSeconds),
                            'shooting')
                        lastFirePulseAt = now
                    else
                        if now - fireStartedAt >= Config.SelfControl.AutomaticFireThresholdMilliseconds then
                            fireBurst = true
                        end
                        if fireBurst and now - lastFirePulseAt >= Config.SelfControl.ContinuousRefreshSeconds * 1000 then
                            pulse(Config.SelfControl.ContinuousFireIntensity,
                                Config.SelfControl.ContinuousRefreshSeconds, 'automatic fire')
                            lastFirePulseAt = now
                        end
                    end
                    wasFiring = true
                elseif wasFiring then
                    wasFiring = false
                    if fireBurst then
                        stopToy()
                        fireBurst = false
                    end
                end

                if Config.SelfControl.EnableFalls then
                    local falling = IsPedFalling(ped)
                    local ragdoll = IsPedRagdoll(ped)
                    if falling and not wasFalling and eventReady('fall') then
                        pulse(Config.SelfControl.FallIntensity, Config.SelfControl.FallDurationSeconds, 'fall')
                    elseif ragdoll and not wasRagdoll and eventReady('ragdoll') then
                        pulse(Config.SelfControl.FallIntensity, Config.SelfControl.FallDurationSeconds, 'ragdoll')
                    end
                    wasFalling = falling
                    wasRagdoll = ragdoll
                end

                if Config.SelfControl.EnableCollisions and IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    local speed = GetEntitySpeed(vehicle)
                    local speedDrop = lastVehicleSpeed - speed
                    local collided = HasEntityCollidedWithAnything(vehicle)
                    if (speedDrop >= Config.SelfControl.CollisionSpeedDrop
                        or (collided and speed >= Config.SelfControl.MinimumCollisionSpeed))
                        and eventReady('vehicle_collision', Config.SelfControl.CollisionCooldownMilliseconds) then
                        pulse(Config.SelfControl.CollisionIntensity, Config.SelfControl.CollisionDurationSeconds, 'vehicle collision')
                    end
                    lastVehicleSpeed = speed
                else
                    lastVehicleSpeed = 0.0
                end

                if Config.SelfControl.EnableMelee then
                    local melee = IsPedInMeleeCombat(ped)
                    if melee and not wasMelee and eventReady('melee') then
                        pulse(Config.SelfControl.MeleeIntensity, Config.SelfControl.MeleeDurationSeconds, 'melee')
                    end
                    wasMelee = melee
                end
            end
        end
    end
end)

AddEventHandler('gameEventTriggered', function(eventName, args)
    if not gameplayEnabled or not args then return end

    local ped = PlayerPedId()
    if ped == 0 then return end

    if eventName == 'CEventNetworkEntityDamage'
        and Config.SelfControl.EnableDamage
        and args[1] == ped
        and eventReady('damage') then
        pulse(Config.SelfControl.DamageIntensity, Config.SelfControl.DamageDurationSeconds, 'damage')

    elseif eventName == 'CEventShockingExplosion'
        and Config.SelfControl.EnableExplosions
        and eventReady('explosion', Config.SelfControl.ExplosionCooldownMilliseconds) then
        pulse(Config.SelfControl.ExplosionIntensity, Config.SelfControl.ExplosionDurationSeconds, 'explosion')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        stopToy(true)
        SetNuiFocus(false, false)
    end
end)


-- Detect impacts with configured roadside props. The server validates and broadcasts
-- each accepted hit so every connected Self Control client can react.
local bollardModels = {}
for _, modelName in ipairs(Config.Bollards.Models or {}) do
    bollardModels[GetHashKey(modelName)] = true
end
local bollardStates = {}
local bollardIntensity = 0
local lastBollardHitAt = 0
local lastBollardPulseAt = 0
local bollardFromPartner = false

RegisterNetEvent('xtoys:selfControlBollardHit', function(fromPartner)
    if not gameplayEnabled or not Config.Bollards.Enabled then return end
    bollardIntensity = math.min(Config.MaxIntensity,
        bollardIntensity + (Config.Bollards.IntensityStep or 10))
    lastBollardHitAt = GetGameTimer()
    bollardFromPartner = fromPartner == true
    receivingPartnerEvent = bollardFromPartner
    pulse(bollardIntensity, 2, 'bollard impact')
    receivingPartnerEvent = false
    lastBollardPulseAt = lastBollardHitAt
end)

CreateThread(function()
    while true do
        Wait(Config.Bollards.ScanIntervalMilliseconds or 200)
        if Config.Bollards.Enabled and gameplayEnabled then
            local ped = PlayerPedId()
            if ped ~= 0 and DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local vehicleCoords = GetEntityCoords(vehicle)
                for _, object in ipairs(GetGamePool('CObject')) do
                    if DoesEntityExist(object) and bollardModels[GetEntityModel(object)] then
                        local coords = GetEntityCoords(object)
                        if #(vehicleCoords - coords) <= (Config.Bollards.NearbyDistanceMeters or 8) then
                            local rotation = GetEntityRotation(object, 2)
                            local tipped = math.max(math.abs(rotation.x), math.abs(rotation.y))
                                >= (Config.Bollards.TipAngleDegrees or 30)
                            local velocity = GetEntityVelocity(object)
                            local speed = #velocity
                            local state = bollardStates[object]
                            if not state then
                                bollardStates[object] = { coords = coords, tipped = tipped, reported = false }
                            else
                                local moved = #(coords - state.coords)
                                local knocked = (tipped and not state.tipped) or moved >= 0.45 or speed >= 0.8
                                if knocked and not state.reported then
                                    TriggerServerEvent('xtoys:reportSelfControlBollardHit',
                                        coords.x, coords.y, coords.z, GetEntityModel(object))
                                    state.reported = true
                                end
                                if not state.reported then state.coords = coords end
                                state.tipped = tipped
                            end
                        end
                    end
                end
                for object in pairs(bollardStates) do
                    if not DoesEntityExist(object) then bollardStates[object] = nil end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        if lastBollardHitAt > 0 and gameplayEnabled then
            local now = GetGameTimer()
            if now - lastBollardHitAt >= (Config.Bollards.IdleStopMilliseconds or 30000) then
                bollardIntensity = 0
                lastBollardHitAt = 0
                stopToy()
            elseif now - lastBollardPulseAt >= 900 then
                receivingPartnerEvent = bollardFromPartner
                pulse(bollardIntensity, 2, 'bollard hold')
                receivingPartnerEvent = false
                lastBollardPulseAt = now
            end
        elseif not gameplayEnabled then
            bollardIntensity = 0
            lastBollardHitAt = 0
        end
    end
end)

