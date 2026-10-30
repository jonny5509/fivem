local debugEnabled = Config.Debug == true
local gameplayEnabled = true
local gameplayActive = false
local lastEventAt = 0
local lastVehicleSpeed = 0
local wasFiring = false
local wasMelee = false

local function log(message)
    if debugEnabled then
        print(('[xToys Self Control:DEBUG] %s'):format(tostring(message)))
    end
end

local function notify(message)
    SendNUIMessage({ type = 'toast', message = message })
end

local function pulse(intensity, duration)
    if not gameplayEnabled then return end

    intensity = math.max(0, math.min(Config.MaxIntensity, tonumber(intensity) or 0))
    duration = math.max(1, tonumber(duration) or 1)

    gameplayActive = true
    log(('Pulse: intensity=%d duration=%s'):format(intensity, tostring(duration)))
    SendNUIMessage({
        type = 'xtoysCommand',
        action = Config.XToysActions.SetIntensity,
        intensity = intensity,
        duration = duration
    })
end

local function stopToy()
    if gameplayActive then
        SendNUIMessage({ type = 'xtoysStop', action = Config.XToysActions.Stop })
        gameplayActive = false
        log('Stop sent.')
    end
end

local function connectFromCommand(webhookId)
    webhookId = tostring(webhookId or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if webhookId == '' then
        notify('Usage: /xtoysconnect YOUR_PRIVATE_WEBHOOK_ID')
        return
    end
    SendNUIMessage({ type = 'connectWebhook', webhookId = webhookId })
end

RegisterCommand(Config.OpenCommand, function()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
end, false)

RegisterCommand(Config.StopCommand, function()
    stopToy()
    SendNUIMessage({ type = 'xtoysStop', action = Config.XToysActions.Stop })
    notify('Emergency stop sent.')
end, false)

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
    else
        notify('Client debug logging: ' .. (debugEnabled and 'ON' or 'OFF'))
    end
end, false)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('setEnabled', function(data, cb)
    gameplayEnabled = data.enabled == true
    if not gameplayEnabled then stopToy() end
    SendNUIMessage({ type = 'enabledState', enabled = gameplayEnabled })
    cb({ ok = true })
end)

RegisterNUICallback('emergencyStop', function(_, cb)
    stopToy()
    SendNUIMessage({ type = 'xtoysStop', action = Config.XToysActions.Stop })
    cb({ ok = true })
end)

RegisterNetEvent('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerEvent('chat:addSuggestion', '/' .. Config.OpenCommand, 'Open xToys Self Control')
    TriggerEvent('chat:addSuggestion', '/' .. Config.ConnectCommand, 'Connect your private xToys webhook', {
        { name = 'webhook_id', help = 'Your private XToys webhook ID' }
    })
    TriggerEvent('chat:addSuggestion', '/' .. Config.StopCommand, 'Emergency stop your xToys device')
end)

CreateThread(function()
    while true do
        Wait(Config.SelfControl.PollMilliseconds)

        if not gameplayEnabled then
            wasFiring = false
            wasMelee = false
            stopToy()
        else
            local ped = PlayerPedId()
            local now = GetGameTimer()
            local firing = IsPedShooting(ped)

            if firing then
                if not wasFiring then
                    local duration = math.random(Config.SelfControl.ShotMinSeconds, Config.SelfControl.ShotMaxSeconds)
                    pulse(Config.SelfControl.ContinuousFireIntensity, duration)
                else
                    pulse(Config.SelfControl.ContinuousFireIntensity, Config.SelfControl.ContinuousRefreshSeconds)
                end
            elseif wasFiring then
                stopToy()
            end
            wasFiring = firing

            if Config.SelfControl.EnableFalls
                and (IsPedFalling(ped) or IsPedRagdoll(ped))
                and now - lastEventAt >= Config.SelfControl.EventCooldownMilliseconds then
                lastEventAt = now
                pulse(Config.SelfControl.FallIntensity, Config.SelfControl.FallDurationSeconds)
            end

            if Config.SelfControl.EnableCollisions and IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local speed = GetEntitySpeed(vehicle)
                if lastVehicleSpeed - speed > 8.0
                    and now - lastEventAt >= Config.SelfControl.EventCooldownMilliseconds then
                    lastEventAt = now
                    pulse(Config.SelfControl.CollisionIntensity, Config.SelfControl.CollisionDurationSeconds)
                end
                lastVehicleSpeed = speed
            else
                lastVehicleSpeed = 0
            end

            if Config.SelfControl.EnableMelee then
                local melee = IsPedInMeleeCombat(ped)
                if melee and not wasMelee
                    and now - lastEventAt >= Config.SelfControl.EventCooldownMilliseconds then
                    lastEventAt = now
                    pulse(Config.SelfControl.MeleeIntensity, Config.SelfControl.MeleeDurationSeconds)
                end
                wasMelee = melee
            end
        end
    end
end)

AddEventHandler('gameEventTriggered', function(eventName, args)
    if not gameplayEnabled or not args then return end

    local ped = PlayerPedId()
    local now = GetGameTimer()

    if eventName == 'CEventNetworkEntityDamage'
        and args[1] == ped
        and Config.SelfControl.EnableDamage
        and now - lastEventAt >= Config.SelfControl.EventCooldownMilliseconds then
        lastEventAt = now
        pulse(Config.SelfControl.DamageIntensity, Config.SelfControl.DamageDurationSeconds)

    elseif eventName == 'CEventShockingExplosion'
        and Config.SelfControl.EnableExplosions
        and now - lastEventAt >= Config.SelfControl.EventCooldownMilliseconds then
        lastEventAt = now
        pulse(Config.SelfControl.ExplosionIntensity, Config.SelfControl.ExplosionDurationSeconds)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        stopToy()
        SetNuiFocus(false, false)
    end
end)
