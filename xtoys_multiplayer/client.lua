local debugEnabled = Config.Debug == true

local function debugLog(message)
    if debugEnabled then
        print(('[xToys:CLIENT:DEBUG] %s'):format(tostring(message)))
    end
end

local function notify(message, kind)
    debugLog(('Notification (%s): %s'):format(tostring(kind or 'info'), tostring(message)))
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
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { '/xtoysdebug on|off|status', 'Enable/disable diagnostic logging or check its status.' }
    })
end

RegisterCommand('xtoysdebug', function(_, args)
    local setting = (args[1] or 'status'):lower()
    if setting == 'on' then
        debugEnabled = true
        TriggerServerEvent('xtoys:debugToggle', true)
        print('[xToys:CLIENT:DEBUG] Debug logging enabled. Check this F8 console and the server console.')
        TriggerEvent('chat:addMessage', { color = { 100, 220, 150 }, args = { 'xToys', 'Debug logging enabled. Check F8 and the server console.' } })
    elseif setting == 'off' then
        debugEnabled = false
        TriggerServerEvent('xtoys:debugToggle', false)
        TriggerEvent('chat:addMessage', { color = { 255, 180, 90 }, args = { 'xToys', 'Client debug logging disabled.' } })
    elseif setting == 'status' then
        TriggerEvent('chat:addMessage', { color = { 167, 139, 250 }, args = { 'xToys', 'Client debug logging: ' .. (debugEnabled and 'ON' or 'OFF') .. '. Use /xtoysdebug on or /xtoysdebug off.' } })
    else
        TriggerEvent('chat:addMessage', { color = { 255, 180, 90 }, args = { 'xToys', 'Usage: /xtoysdebug on|off|status' } })
    end
end, false)

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
    TriggerEvent('chat:addSuggestion', '/xtoysdebug', 'Toggle xToys diagnostic logging', { { name = 'mode', help = 'on, off, or status' } })
end)

RegisterCommand(Config.OpenCommand, function()
    debugLog('Opening menu and requesting state/nearby players.')
    showCommandHelp()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
    TriggerServerEvent('xtoys:requestState')
    TriggerServerEvent('xtoys:getNearby')
    TriggerServerEvent('xtoys:requestAdvancedState')
end, false)

RegisterCommand(Config.StopCommand, function()
    TriggerServerEvent('xtoys:emergencyStop')
end, false)

RegisterNetEvent('xtoys:notify', notify)
RegisterNetEvent('xtoys:state', function(s) debugLog('Received state update.'); SendNUIMessage({ type = 'state', state = s }) end)
RegisterNetEvent('xtoys:nearbyPlayers', function(players) debugLog(('Received nearby-player list (%d entries).'):format(type(players) == 'table' and #players or 0)); SendNUIMessage({ type = 'nearbyPlayers', players = players }) end)
RegisterNetEvent('xtoys:incomingInvite', function(d) SendNUIMessage({ type = 'incomingInvite', data = d }) end)
RegisterNetEvent('xtoys:incomingTrustedInvite', function(d) SendNUIMessage({ type = 'incomingTrustedInvite', data = d }) end)
RegisterNetEvent('xtoys:incomingControl', function(d) SendNUIMessage({ type = 'incomingControl', data = d }) end)
RegisterNetEvent('xtoys:controlGranted', function(ownerId, ownerName)
    SendNUIMessage({ type = 'controlGranted', ownerId = ownerId, ownerName = ownerName })
end)

RegisterNetEvent('xtoys:receiveControl', function(controllerId, intensity, duration)
    debugLog(('Control command received from server (controller %s, intensity %s, duration %s).'):format(tostring(controllerId), tostring(intensity), tostring(duration)))
    SendNUIMessage({ type = 'xtoysCommand', action = Config.XToysActions.setIntensity,
        intensity = intensity, duration = duration, controllerId = controllerId })
end)
RegisterNetEvent('xtoys:stopLocal', function()
    debugLog('Emergency/remote stop event received.')
    SendNUIMessage({ type = 'xtoysStop', action = Config.XToysActions.stop })
end)

RegisterNUICallback('close', function(_, cb) SetNuiFocus(false, false); cb({ ok = true }) end)
RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('xtoys:requestState'); TriggerServerEvent('xtoys:getNearby'); TriggerServerEvent('xtoys:requestAdvancedState'); cb({ ok = true })
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


local selfMode = Config.SelfControl.EnabledByDefault
local gameplayActive, lastEvent, lastSpeed = false, 0, 0
local function pulse(intensity,seconds)
 if not selfMode then return end
 gameplayActive=true
 SendNUIMessage({type='xtoysCommand',action=Config.XToysActions.setIntensity,intensity=math.max(0,math.min(Config.MaxIntensity,intensity)),duration=seconds})
end
local function stopGameplay()
 if gameplayActive then SendNUIMessage({type='xtoysStop',action=Config.XToysActions.stop}); gameplayActive=false end
end
RegisterNetEvent('xtoys:advancedState',function(data)
 selfMode=data.controlMode=='self'
 SendNUIMessage({type='advancedState',state=data})
 if not selfMode then stopGameplay() end
end)
RegisterNUICallback('setControlMode',function(d,cb) TriggerServerEvent('xtoys:setControlMode',d.mode); cb({ok=true}) end)
RegisterNUICallback('setQiuiEnabled',function(d,cb) TriggerServerEvent('xtoys:setQiuiEnabled',d.enabled==true); cb({ok=true}) end)
RegisterNUICallback('qiuiAction',function(d,cb) TriggerServerEvent('xtoys:qiuiRequest',d.action); cb({ok=true}) end)
CreateThread(function()
 local firing=false
 while true do
  Wait(Config.SelfControl.PollMilliseconds)
  if selfMode then
   local ped=PlayerPedId()
   local shooting=IsPedShooting(ped)
   if shooting then
    if not firing then pulse(Config.SelfControl.ContinuousFireIntensity, math.random(Config.SelfControl.ShotMinSeconds, Config.SelfControl.ShotMaxSeconds))
    else pulse(Config.SelfControl.ContinuousFireIntensity,1) end
   elseif firing then stopGameplay() end
   firing=shooting
   local now=GetGameTimer()
   if Config.SelfControl.EnableFalls and (IsPedFalling(ped) or IsPedRagdoll(ped)) and now-lastEvent>Config.SelfControl.EventCooldownMilliseconds then
    lastEvent=now; pulse(Config.SelfControl.FallIntensity,1)
   end
   if Config.SelfControl.EnableCollisions and IsPedInAnyVehicle(ped,false) then
    local v=GetVehiclePedIsIn(ped,false); local speed=GetEntitySpeed(v)
    if lastSpeed-speed>8.0 and now-lastEvent>Config.SelfControl.EventCooldownMilliseconds then lastEvent=now; pulse(Config.SelfControl.CollisionIntensity,1) end
    lastSpeed=speed
   else lastSpeed=0 end
  else firing=false; stopGameplay(); Wait(200) end
 end
end)
AddEventHandler('gameEventTriggered',function(name,args)
 if not selfMode then return end
 local ped=PlayerPedId(); local now=GetGameTimer()
 if name=='CEventNetworkEntityDamage' and args and args[1]==ped and Config.SelfControl.EnableDamage and now-lastEvent>Config.SelfControl.EventCooldownMilliseconds then
  lastEvent=now; pulse(Config.SelfControl.DamageIntensity,2)
 elseif name=='CEventShockingExplosion' and Config.SelfControl.EnableExplosions and now-lastEvent>Config.SelfControl.EventCooldownMilliseconds then
  lastEvent=now; pulse(Config.SelfControl.ExplosionIntensity,2)
 end
end)
