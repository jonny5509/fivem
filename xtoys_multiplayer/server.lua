local paired, pendingInvites, pendingControl, activeController = {}, {}, {}, {}
local pendingTrustedInvites, trusted = {}, {}

local function identifier(src)
    for _, value in ipairs(GetPlayerIdentifiers(src)) do
        if value:sub(1, 8) == 'license:' then return value end
    end
    return nil
end

local function isTrusted(a, b)
    local aid, bid = identifier(a), identifier(b)
    return aid and bid and trusted[aid] and trusted[aid][bid] ~= nil
end

local function saveTrusted()
    SetResourceKvp('xtoys_trusted_v1', json.encode(trusted))
end

local function loadTrusted()
    local raw = GetResourceKvpString('xtoys_trusted_v1')
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then trusted = data end
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then loadTrusted() end
end)

local function msg(src, message, kind)
    TriggerClientEvent('xtoys:notify', src, message, kind or 'info')
end

local function partnerOf(src)
    local p = paired[src]
    if p and paired[p] == src then return p end
    return nil
end

local function findOnline(identifierValue)
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        if identifier(id) == identifierValue then return id end
    end
    return nil
end

local function trustedList(src)
    local own = identifier(src)
    local result = {}
    if not own or not trusted[own] then return result end
    for partnerId, record in pairs(trusted[own]) do
        local onlineId = findOnline(partnerId)
        result[#result + 1] = {
            identifier = partnerId,
            name = (onlineId and GetPlayerName(onlineId)) or (type(record) == 'table' and record.name) or 'Unknown player',
            online = onlineId ~= nil,
            serverId = onlineId
        }
    end
    table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
    return result
end

local function state(src)
    local p = partnerOf(src)
    local inv = pendingInvites[src]
    local req = pendingControl[src]
    local trustedInv = pendingTrustedInvites[src]
    TriggerClientEvent('xtoys:state', src, {
        paired = p ~= nil,
        partnerId = p,
        partnerName = p and GetPlayerName(p) or nil,
        incomingInvite = inv and { from = inv.from, name = GetPlayerName(inv.from) } or nil,
        incomingTrustedInvite = trustedInv and { from = trustedInv.from, name = GetPlayerName(trustedInv.from) } or nil,
        incomingControl = req and { from = req.from, name = GetPlayerName(req.from) } or nil,
        hasControl = p and activeController[p] == src or false,
        trustedPartners = trustedList(src)
    })
end

local function stopLocal(src)
    if src and GetPlayerName(src) then TriggerClientEvent('xtoys:stopLocal', src) end
end

local function unpair(a, b, reason)
    paired[a], paired[b] = nil, nil
    activeController[a], activeController[b] = nil, nil
    pendingControl[a], pendingControl[b] = nil, nil
    pendingInvites[a], pendingInvites[b] = nil, nil
    stopLocal(a); stopLocal(b)
    if GetPlayerName(a) then
        TriggerClientEvent('xtoys:state', a, { paired = false, trustedPartners = trustedList(a) })
        if reason then msg(a, reason, 'warning') end
    end
    if GetPlayerName(b) then
        TriggerClientEvent('xtoys:state', b, { paired = false, trustedPartners = trustedList(b) })
        if reason then msg(b, reason, 'warning') end
    end
end

local function grantControl(controller, owner)
    activeController[controller] = owner
    TriggerClientEvent('xtoys:controlGranted', controller, owner, GetPlayerName(owner))
    msg(owner, 'Control is active. Use Emergency Stop or Revoke at any time.')
    msg(controller, 'Control granted.')
    state(owner); state(controller)
end

RegisterNetEvent('xtoys:requestState', function() state(source) end)

RegisterNetEvent('xtoys:getNearby', function()
    local src = source
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local origin = GetEntityCoords(ped)
    local result = {}
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        if id ~= src then
            local targetPed = GetPlayerPed(id)
            if targetPed ~= 0 then
                local distance = #(origin - GetEntityCoords(targetPed))
                if distance <= 10.0 then
                    result[#result + 1] = { serverId = id, name = GetPlayerName(id), distance = math.floor(distance + 0.5), trusted = isTrusted(src, id) }
                end
            end
        end
    end
    table.sort(result, function(a, b) return a.distance < b.distance end)
    TriggerClientEvent('xtoys:nearbyPlayers', src, result)
end)

RegisterNetEvent('xtoys:invite', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not GetPlayerName(target) then return msg(src, 'Invalid player server ID.', 'error') end
    if partnerOf(src) or partnerOf(target) then return msg(src, 'One of you is already paired.', 'error') end
    if pendingInvites[target] or pendingInvites[src] then return msg(src, 'A pairing invitation is already pending.', 'error') end
    pendingInvites[target] = { from = src }
    TriggerClientEvent('xtoys:incomingInvite', target, { from = src, name = GetPlayerName(src) })
    msg(src, 'Invitation sent. Waiting for consent.')
    state(target)
    SetTimeout(Config.InviteTimeoutSeconds * 1000, function()
        if pendingInvites[target] and pendingInvites[target].from == src then
            pendingInvites[target] = nil
            msg(src, 'Pairing invitation expired.', 'warning')
            msg(target, 'Pairing invitation expired.', 'warning')
            state(target)
        end
    end)
end)

RegisterNetEvent('xtoys:acceptInvite', function()
    local src = source
    local inv = pendingInvites[src]
    if not inv or not GetPlayerName(inv.from) then pendingInvites[src] = nil; return msg(src, 'Invitation expired.', 'error') end
    local other = inv.from
    if partnerOf(src) or partnerOf(other) then pendingInvites[src] = nil; return msg(src, 'One of you is already paired.', 'error') end
    pendingInvites[src] = nil
    paired[src], paired[other] = other, src
    msg(src, 'Pairing accepted.')
    msg(other, (GetPlayerName(src) or 'Your partner') .. ' accepted.')
    state(src); state(other)
end)

RegisterNetEvent('xtoys:declineInvite', function()
    local src = source
    local inv = pendingInvites[src]
    if not inv then return end
    pendingInvites[src] = nil
    msg(src, 'Invitation declined.')
    msg(inv.from, (GetPlayerName(src) or 'Player') .. ' declined your invitation.', 'warning')
    state(inv.from)
end)

RegisterNetEvent('xtoys:trustedInvite', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not GetPlayerName(target) then return msg(src, 'Invalid player server ID.', 'error') end
    local a, b = identifier(src), identifier(target)
    if not a or not b then return msg(src, 'Could not verify both players\' license identifiers.', 'error') end
    local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target)))
    if distance > 10.0 then return msg(src, 'That player must be within 10 metres to add them.', 'error') end
    if isTrusted(src, target) then return msg(src, 'That player is already a trusted partner.', 'warning') end
    if partnerOf(src) or partnerOf(target) then return msg(src, 'End the current control pairing before creating a trusted partnership.', 'error') end
    if pendingTrustedInvites[target] or pendingTrustedInvites[src] then return msg(src, 'A trusted-partner invitation is already pending.', 'error') end
    pendingTrustedInvites[target] = { from = src }
    TriggerClientEvent('xtoys:incomingTrustedInvite', target, { from = src, name = GetPlayerName(src) })
    msg(src, 'Trusted-partner invitation sent. They must confirm once.')
    state(target)
    SetTimeout(Config.InviteTimeoutSeconds * 1000, function()
        if pendingTrustedInvites[target] and pendingTrustedInvites[target].from == src then
            pendingTrustedInvites[target] = nil
            msg(src, 'Trusted-partner invitation expired.', 'warning')
            msg(target, 'Trusted-partner invitation expired.', 'warning')
            state(target)
        end
    end)
end)

RegisterNetEvent('xtoys:acceptTrustedInvite', function()
    local src = source
    local inv = pendingTrustedInvites[src]
    if not inv or not GetPlayerName(inv.from) then pendingTrustedInvites[src] = nil; return msg(src, 'Trusted invitation expired.', 'error') end
    local other = inv.from
    if partnerOf(src) or partnerOf(other) then pendingTrustedInvites[src] = nil; return msg(src, 'One of you is already paired.', 'error') end
    local a, b = identifier(src), identifier(other)
    if not a or not b then pendingTrustedInvites[src] = nil; return msg(src, 'Could not verify player identifiers.', 'error') end
    pendingTrustedInvites[src] = nil
    trusted[a] = trusted[a] or {}; trusted[b] = trusted[b] or {}
    trusted[a][b] = { name = GetPlayerName(other) }
    trusted[b][a] = { name = GetPlayerName(src) }
    saveTrusted()
    paired[src], paired[other] = other, src
    msg(src, 'Trusted partnership confirmed and saved.')
    msg(other, (GetPlayerName(src) or 'Player') .. ' is now your trusted partner.')
    state(src); state(other)
end)

RegisterNetEvent('xtoys:declineTrustedInvite', function()
    local src = source
    local inv = pendingTrustedInvites[src]
    if not inv then return end
    pendingTrustedInvites[src] = nil
    msg(src, 'Trusted-partner invitation declined.')
    if GetPlayerName(inv.from) then msg(inv.from, (GetPlayerName(src) or 'Player') .. ' declined your trusted invitation.', 'warning'); state(inv.from) end
end)

RegisterNetEvent('xtoys:removeTrusted', function(partnerIdentifier)
    local src = source
    local own = identifier(src)
    if not own or type(partnerIdentifier) ~= 'string' or not (trusted[own] and trusted[own][partnerIdentifier]) then
        return msg(src, 'Trusted partner not found.', 'error')
    end
    trusted[own][partnerIdentifier] = nil
    if next(trusted[own]) == nil then trusted[own] = nil end
    if trusted[partnerIdentifier] then
        trusted[partnerIdentifier][own] = nil
        if next(trusted[partnerIdentifier]) == nil then trusted[partnerIdentifier] = nil end
    end
    local online = findOnline(partnerIdentifier)
    if online and partnerOf(src) == online then unpair(src, online, 'Trusted partnership removed; control stopped.') end
    saveTrusted()
    msg(src, 'Trusted partnership removed.')
    state(src)
    if online then state(online); msg(online, 'Your trusted partnership was removed.', 'warning') end
end)

RegisterNetEvent('xtoys:requestControl', function()
    local src = source
    local target = partnerOf(src)
    if not target then return msg(src, 'Pair with a player first.', 'error') end
    if activeController[src] == target then return msg(src, 'You already have control.') end
    if isTrusted(src, target) then return grantControl(src, target) end
    if pendingControl[target] then return msg(src, 'A control request is already pending.', 'warning') end
    pendingControl[target] = { from = src }
    TriggerClientEvent('xtoys:incomingControl', target, { from = src, name = GetPlayerName(src) })
    msg(src, 'Control request sent; your partner must approve.')
    state(target)
    SetTimeout(Config.ControlRequestTimeoutSeconds * 1000, function()
        if pendingControl[target] and pendingControl[target].from == src then
            pendingControl[target] = nil
            msg(src, 'Control request expired.', 'warning')
            msg(target, 'Control request expired.', 'warning')
            state(target)
        end
    end)
end)

RegisterNetEvent('xtoys:startTrustedControl', function(target)
    local src = source
    target = tonumber(target)
    if not target or not GetPlayerName(target) or not isTrusted(src, target) then return msg(src, 'That player is not an online trusted partner.', 'error') end
    if partnerOf(src) == target then
        if activeController[src] == target then return msg(src, 'You already have control.') end
        return grantControl(src, target)
    end
    if partnerOf(src) or partnerOf(target) then return msg(src, 'One of you is already paired with someone else.', 'error') end
    paired[src], paired[target] = target, src
    grantControl(src, target)
end)

RegisterNetEvent('xtoys:approveControl', function(approved)
    local owner = source
    local req = pendingControl[owner]
    if not req then return msg(owner, 'No pending control request.', 'error') end
    pendingControl[owner] = nil
    local controller = req.from
    if partnerOf(owner) ~= controller then return msg(owner, 'Pairing has ended.', 'error') end
    if approved == true then grantControl(controller, owner)
    else
        msg(owner, 'Control request declined.')
        msg(controller, 'Your control request was declined.', 'warning')
        state(owner); state(controller)
    end
end)

RegisterNetEvent('xtoys:controlCommand', function(intensity, duration)
    local src = source
    local target = partnerOf(src)
    if not target or activeController[src] ~= target then return msg(src, 'You do not have approved control.', 'error') end
    intensity, duration = tonumber(intensity), tonumber(duration)
    if not intensity or not duration then return end
    intensity = math.floor(math.max(0, math.min(Config.MaxIntensity, intensity)))
    duration = math.floor(math.max(1, math.min(Config.MaxDurationSeconds, duration)))
    TriggerClientEvent('xtoys:receiveControl', target, src, intensity, duration)
end)

RegisterNetEvent('xtoys:revoke', function()
    local src = source
    local p = partnerOf(src)
    if p then unpair(src, p, 'Pairing revoked. Remote control stopped.') end
end)

RegisterNetEvent('xtoys:emergencyStop', function()
    local src = source
    local p = partnerOf(src)
    if p then
        activeController[src], activeController[p] = nil, nil
        pendingControl[src], pendingControl[p] = nil, nil
        stopLocal(src); stopLocal(p)
        msg(src, 'Emergency stop sent.')
        msg(p, 'Your partner triggered emergency stop.', 'warning')
        state(src); state(p)
    else
        stopLocal(src)
        msg(src, 'Local emergency stop sent.')
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local p = partnerOf(src)
    if p then unpair(src, p, 'Your partner disconnected; the session was stopped.') end
    for target, inv in pairs(pendingInvites) do
        if target == src or inv.from == src then
            pendingInvites[target] = nil
            if target ~= src and GetPlayerName(target) then msg(target, 'Invitation cancelled because the sender disconnected.', 'warning') end
        end
    end
    for target, inv in pairs(pendingTrustedInvites) do
        if target == src or inv.from == src then
            pendingTrustedInvites[target] = nil
            if target ~= src and GetPlayerName(target) then msg(target, 'Trusted invitation cancelled because the sender disconnected.', 'warning') end
        end
    end
    for owner, req in pairs(pendingControl) do
        if owner == src or req.from == src then
            pendingControl[owner] = nil
            if owner ~= src and GetPlayerName(owner) then msg(owner, 'Control request cancelled because the requester disconnected.', 'warning') end
        end
    end
end)
