local function notify(message, kind)
    SendNUIMessage({ type = 'toast', message = message, kind = kind or 'info' })
end

RegisterCommand(Config.OpenCommand, function()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
    TriggerServerEvent('xtoys:requestState')
end, false)

RegisterCommand(Config.StopCommand, function()
    TriggerServerEvent('xtoys:emergencyStop')
end, false)

RegisterNetEvent('xtoys:notify', notify)
RegisterNetEvent('xtoys:state', function(s) SendNUIMessage({ type = 'state', state = s }) end)
RegisterNetEvent('xtoys:incomingInvite', function(d) SendNUIMessage({ type = 'incomingInvite', data = d }) end)
RegisterNetEvent('xtoys:incomingControl', function(d) SendNUIMessage({ type = 'incomingControl', data = d }) end)
RegisterNetEvent('xtoys:controlGranted', function(ownerId, ownerName)
    SendNUIMessage({ type = 'controlGranted', ownerId = ownerId, ownerName = ownerName })
end)

-- Only the device owner's client receives this event and holds their private webhook ID.
RegisterNetEvent('xtoys:receiveControl', function(controllerId, intensity, duration)
    SendNUIMessage({ type = 'xtoysCommand', action = Config.XToysActions.setIntensity,
        intensity = intensity, duration = duration, controllerId = controllerId })
end)
RegisterNetEvent('xtoys:stopLocal', function()
    SendNUIMessage({ type = 'xtoysStop', action = Config.XToysActions.stop })
end)

RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false); cb({ ok = true }) end)
RegisterNUICallback('refresh', function(_, cb) TriggerServerEvent('xtoys:requestState'); cb({ ok = true }) end)
RegisterNUICallback('invite', function(d, cb) TriggerServerEvent('xtoys:invite', d.target); cb({ ok = true }) end)
RegisterNUICallback('acceptInvite', function(_, cb) TriggerServerEvent('xtoys:acceptInvite'); cb({ ok = true }) end)
RegisterNUICallback('declineInvite', function(_, cb) TriggerServerEvent('xtoys:declineInvite'); cb({ ok = true }) end)
RegisterNUICallback('requestControl', function(_, cb) TriggerServerEvent('xtoys:requestControl'); cb({ ok = true }) end)
RegisterNUICallback('approveControl', function(d, cb) TriggerServerEvent('xtoys:approveControl', d.approved == true); cb({ ok = true }) end)
RegisterNUICallback('control', function(d, cb) TriggerServerEvent('xtoys:controlCommand', d.intensity, d.duration); cb({ ok = true }) end)
RegisterNUICallback('revoke', function(_, cb) TriggerServerEvent('xtoys:revoke'); cb({ ok = true }) end)
RegisterNUICallback('emergencyStop', function(_, cb) TriggerServerEvent('xtoys:emergencyStop'); cb({ ok = true }) end)
RegisterNUICallback('saveWebhook', function(d, cb)
    -- NUI-local only: never emit credentials to the FiveM server.
    SendNUIMessage({ type = 'saveWebhook', webhookId = d.webhookId })
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
