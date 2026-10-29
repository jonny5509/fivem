local function notify(message, kind)
    SendNUIMessage({ type = 'toast', message = message, kind = kind or 'info' })
end

local function showCommandHelp()
    TriggerEvent('chat:addMessage', {
        color = { 167, 139, 250 },
        multiline = true,
        args = { 'xToys', 'Available commands:' }
    })
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { '/xtoys', 'Open the xToys menu (pairing, trusted partners and controls).' }
    })
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { '/xtoyshelp', 'Show this command list again.' }
    })
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { '/xtoysid YOUR_WEBHOOK_ID', 'Set your private xToys webhook ID and connect.' }
    })
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { '/xtoysstop', 'Immediately send an emergency stop.' }
    })
end

RegisterCommand('xtoyshelp', function()
    showCommandHelp()
end, false)

RegisterCommand('xtoysid', function(_, args)
    local webhookId = table.concat(args, ' ')
    if not webhookId or webhookId == '' then
        TriggerEvent('chat:addMessage', {
            color = { 255, 180, 90 },
            args = { 'xToys', 'Usage: /xtoysid YOUR_WEBHOOK_ID' }
        })
        return
    end
    SendNUIMessage({ type = 'setWebhookId', webhookId = webhookId })
    TriggerEvent('chat:addMessage', {
        color = { 100, 220, 150 },
        args = { 'xToys', 'Webhook ID sent to your local xToys menu. Connecting...' }
    })
end, false)

RegisterNetEvent('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerEvent('chat:addSuggestion', '/xtoys', 'Open the xToys menu and show commands')
    TriggerEvent('chat:addSuggestion', '/xtoyshelp', 'Show the xToys command list')
    TriggerEvent('chat:addSuggestion', '/xtoysid', 'Set your private xToys webhook ID', {
        { name = 'webhook_id', help = 'Your private xToys webhook ID' }
    })
    TriggerEvent('chat:addSuggestion', '/xtoysstop', 'Emergency stop the active xToys session')
end)

RegisterCommand(Config.OpenCommand, function()
    showCommandHelp()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
    TriggerServerEvent('xtoys:requestState')
    TriggerServerEvent('xtoys:getNearby')
end, false)

RegisterCommand(Config.StopCommand, function()
    TriggerServerEvent('xtoys:emergencyStop')
end, false)

RegisterNetEvent('xtoys:notify', notify)
RegisterNetEvent('xtoys:state', function(s) SendNUIMessage({ type = 'state', state = s }) end)
RegisterNetEvent('xtoys:nearbyPlayers', function(players) SendNUIMessage({ type = 'nearbyPlayers', players = players }) end)
RegisterNetEvent('xtoys:incomingInvite', function(d) SendNUIMessage({ type = 'incomingInvite', data = d }) end)
RegisterNetEvent('xtoys:incomingTrustedInvite', function(d) SendNUIMessage({ type = 'incomingTrustedInvite', data = d }) end)
RegisterNetEvent('xtoys:incomingControl', function(d) SendNUIMessage({ type = 'incomingControl', data = d }) end)
RegisterNetEvent('xtoys:controlGranted', function(ownerId, ownerName)
    SendNUIMessage({ type = 'controlGranted', ownerId = ownerId, ownerName = ownerName })
end)

RegisterNetEvent('xtoys:receiveControl', function(controllerId, intensity, duration)
    SendNUIMessage({ type = 'xtoysCommand', action = Config.XToysActions.setIntensity,
        intensity = intensity, duration = duration, controllerId = controllerId })
end)
RegisterNetEvent('xtoys:stopLocal', function()
    SendNUIMessage({ type = 'xtoysStop', action = Config.XToysActions.stop })
end)

RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false); cb({ ok = true }) end)
RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('xtoys:requestState'); TriggerServerEvent('xtoys:getNearby'); cb({ ok = true })
end)
RegisterNUICallback('invite', function(d, cb) TriggerServerEvent('xtoys:invite', d.target); cb({ ok = true }) end)
RegisterNUICallback('acceptInvite', function(_, cb) TriggerServerEvent('xtoys:acceptInvite'); cb({ ok = true }) end)
RegisterNUICallback('declineInvite', function(_, cb) TriggerServerEvent('xtoys:declineInvite'); cb({ ok = true }) end)
RegisterNUICallback('trustedInvite', function(d, cb) TriggerServerEvent('xtoys:trustedInvite', d.target); cb({ ok = true }) end)
RegisterNUICallback('acceptTrustedInvite', function(_, cb) TriggerServerEvent('xtoys:acceptTrustedInvite'); cb({ ok = true }) end)
RegisterNUICallback('declineTrustedInvite', function(_, cb) TriggerServerEvent('xtoys:declineTrustedInvite'); cb({ ok = true }) end)
RegisterNUICallback('removeTrusted', function(d, cb) TriggerServerEvent('xtoys:removeTrusted', d.identifier); cb({ ok = true }) end)
RegisterNUICallback('startTrustedControl', function(d, cb) TriggerServerEvent('xtoys:startTrustedControl', d.target); cb({ ok = true }) end)
RegisterNUICallback('requestControl', function(_, cb) TriggerServerEvent('xtoys:requestControl'); cb({ ok = true }) end)
RegisterNUICallback('approveControl', function(d, cb) TriggerServerEvent('xtoys:approveControl', d.approved == true); cb({ ok = true }) end)
RegisterNUICallback('control', function(d, cb) TriggerServerEvent('xtoys:controlCommand', d.intensity, d.duration); cb({ ok = true }) end)
RegisterNUICallback('revoke', function(_, cb) TriggerServerEvent('xtoys:revoke'); cb({ ok = true }) end)
RegisterNUICallback('emergencyStop', function(_, cb) TriggerServerEvent('xtoys:emergencyStop'); cb({ ok = true }) end)
RegisterNUICallback('saveWebhook', function(d, cb)
    SendNUIMessage({ type = 'saveWebhook', webhookId = d.webhookId })
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
