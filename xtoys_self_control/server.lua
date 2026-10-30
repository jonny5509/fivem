-- Server validation, opt-in partner pairing and event relay for Self Control.
local allowedModels = {}
for _, modelName in ipairs(Config.Bollards.Models or {}) do
    allowedModels[GetHashKey(modelName)] = true
end

local recentHits = {}
local partnerOf = {}
local pendingInvites = {}

local function distanceBetween(a, b)
    local pedA, pedB = GetPlayerPed(a), GetPlayerPed(b)
    if pedA == 0 or pedB == 0 or not DoesEntityExist(pedA) or not DoesEntityExist(pedB) then return math.huge end
    return #(GetEntityCoords(pedA) - GetEntityCoords(pedB))
end

local function closePartners(src)
    local partner = partnerOf[src]
    if not partner then return nil end
    if GetPlayerName(partner) == nil or distanceBetween(src, partner) > (Config.Partner.MaximumDistanceMeters or 15.0) then
        partnerOf[src], partnerOf[partner] = nil, nil
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'Partner sharing ended: partner disconnected or moved out of range.')
        if GetPlayerName(partner) then TriggerClientEvent('xtoys:selfControlPartnerNotice', partner, 'Partner sharing ended: out of range.') end
        return nil
    end
    return partner
end

RegisterNetEvent('xtoys:selfControlPartnerInvite', function(target)
    local src = source
    target = tonumber(target)
    if not Config.Partner.Enabled then return end
    if not target or target == src or GetPlayerName(target) == nil then
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'Invalid partner server ID.') return
    end
    if partnerOf[src] or partnerOf[target] then
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'You or that player already has a partner.') return
    end
    if distanceBetween(src, target) > (Config.Partner.MaximumDistanceMeters or 15.0) then
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'Move within partner range before inviting.') return
    end
    pendingInvites[target] = src
    TriggerClientEvent('xtoys:selfControlPartnerNotice', target,
        ('Player %d invited you to share Self Control events. Use /xtoyspartneraccept %d or /xtoyspartnerdecline %d.'):format(src, src, src))
    TriggerClientEvent('xtoys:selfControlPartnerNotice', src, ('Invitation sent to player %d.'):format(target))
end)

RegisterNetEvent('xtoys:selfControlPartnerAccept', function(inviter)
    local src = source
    inviter = tonumber(inviter)
    if not inviter or pendingInvites[src] ~= inviter or GetPlayerName(inviter) == nil then
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'No matching pending invitation.') return
    end
    if partnerOf[src] or partnerOf[inviter] or distanceBetween(src, inviter) > (Config.Partner.MaximumDistanceMeters or 15.0) then
        pendingInvites[src] = nil
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'Pairing failed: one player is busy or you are too far apart.') return
    end
    partnerOf[src], partnerOf[inviter], pendingInvites[src] = inviter, src, nil
    TriggerClientEvent('xtoys:selfControlPartnerNotice', src, ('Sharing enabled with player %d. Stay within %.0f metres.'):format(inviter, Config.Partner.MaximumDistanceMeters or 15.0))
    TriggerClientEvent('xtoys:selfControlPartnerNotice', inviter, ('Player %d accepted. Shared events are enabled.'):format(src))
end)

RegisterNetEvent('xtoys:selfControlPartnerDecline', function(inviter)
    local src = source
    inviter = tonumber(inviter)
    if pendingInvites[src] == inviter then
        pendingInvites[src] = nil
        TriggerClientEvent('xtoys:selfControlPartnerNotice', inviter, ('Player %d declined your invitation.'):format(src))
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'Invitation declined.')
    end
end)

RegisterNetEvent('xtoys:selfControlPartnerEnd', function()
    local src = source
    local partner = partnerOf[src]
    if partner then
        partnerOf[src], partnerOf[partner] = nil, nil
        TriggerClientEvent('xtoys:selfControlPartnerStop', partner)
        TriggerClientEvent('xtoys:selfControlPartnerNotice', partner, 'Partner sharing was ended.')
        TriggerClientEvent('xtoys:selfControlPartnerNotice', src, 'Partner sharing ended.')
    end
end)

RegisterNetEvent('xtoys:selfControlSharePulse', function(intensity, duration, eventSource)
    local src = source
    local partner = closePartners(src)
    if not partner then return end
    intensity, duration = tonumber(intensity), tonumber(duration)
    if not intensity or not duration or intensity < 1 or intensity > (Config.MaxIntensity or 100)
        or duration < 0.1 or duration > (Config.SelfControl.MaxDurationSeconds or 10) then return end
    TriggerClientEvent('xtoys:selfControlPartnerPulse', partner, intensity, duration, tostring(eventSource or 'gameplay'):sub(1, 40))
end)

RegisterNetEvent('xtoys:selfControlShareStop', function()
    local partner = closePartners(source)
    if partner then TriggerClientEvent('xtoys:selfControlPartnerStop', partner) end
end)

RegisterNetEvent('xtoys:reportSelfControlBollardHit', function(x, y, z, modelHash)
    local src = source
    if not Config.Bollards.Enabled or type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end
    modelHash = tonumber(modelHash)
    if not modelHash or not allowedModels[modelHash] then return end
    local ped = GetPlayerPed(src)
    if ped == 0 or not DoesEntityExist(ped) or not IsPedInAnyVehicle(ped, false) then return end
    local playerCoords = GetEntityCoords(ped)
    local hitCoords = vector3(x, y, z)
    if #(playerCoords - hitCoords) > (Config.Bollards.NearbyDistanceMeters or 8) + 7 then return end
    local key = ('%d:%d:%d'):format(math.floor(x / 2), math.floor(y / 2), math.floor(z / 2))
    local now = GetGameTimer()
    if recentHits[key] and now - recentHits[key] < 1500 then return end
    recentHits[key] = now
    TriggerClientEvent('xtoys:selfControlBollardHit', src, false)
    local partner = closePartners(src)
    if partner then TriggerClientEvent('xtoys:selfControlBollardHit', partner, true) end
    for hitKey, hitTime in pairs(recentHits) do
        if now - hitTime > 10000 then recentHits[hitKey] = nil end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local partner = partnerOf[src]
    if partner then
        partnerOf[src], partnerOf[partner] = nil, nil
        TriggerClientEvent('xtoys:selfControlPartnerStop', partner)
        TriggerClientEvent('xtoys:selfControlPartnerNotice', partner, 'Partner disconnected; sharing ended.')
    end
    for target, inviter in pairs(pendingInvites) do
        if target == src or inviter == src then pendingInvites[target] = nil end
    end
end)
