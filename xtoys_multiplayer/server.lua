local paired, pendingInvites, pendingControl, activeController = {}, {}, {}, {}

local function msg(src, text, kind)
    TriggerClientEvent('xtoys:notify', src, text, kind or 'info')
end

local function partnerOf(src)
    local p = paired[src]
    if p and paired[p] == src then return p end
    return nil
end

local function state(src)
    local p = partnerOf(src)
    local inv = pendingInvites[src]
    local req = pendingControl[src]
    TriggerClientEvent('xtoys:state', src, {
        paired = p ~= nil,
        partnerId = p,
        partnerName = p and GetPlayerName(p) or nil,
        incomingInvite = inv and { from = inv.from, name = GetPlayerName(inv.from) } or nil,
        incomingControl = req and { from = req.from, name = GetPlayerName(req.from) } or nil,
        hasControl = p and activeController[p] == src or false
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
        TriggerClientEvent('xtoys:state', a, { paired = false })
        if reason then msg(a, reason, 'warning') end
    end
    if GetPlayerName(b) then
        TriggerClientEvent('xtoys:state', b, { paired = false })
        if reason then msg(b, reason, 'warning') end
    end
end

RegisterNetEvent('xtoys:requestState', function() state(source) end)

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

RegisterNetEvent('xtoys:requestControl', function()
    local src = source
    local target = partnerOf(src)
    if not target then return msg(src, 'Pair with a player first.', 'error') end
    if activeController[src] == target then return msg(src, 'You already have approved control.') end
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

RegisterNetEvent('xtoys:approveControl', function(approved)
    local owner = source
    local req = pendingControl[owner]
    if not req then return msg(owner, 'No pending control request.', 'error') end
    pendingControl[owner] = nil
    local controller = req.from
    if partnerOf(owner) ~= controller then return msg(owner, 'Pairing has ended.', 'error') end
    if approved == true then
        -- One active controller at a time; approval is explicit and can be revoked by either party.
        activeController[controller] = owner
        TriggerClientEvent('xtoys:controlGranted', controller, owner, GetPlayerName(owner))
        msg(owner, 'Control approved. Use Emergency Stop or Revoke at any time.')
        msg(controller, 'Your partner approved control.')
    else
        msg(owner, 'Control request declined.')
        msg(controller, 'Your control request was declined.', 'warning')
    end
    state(owner); state(controller)
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
            if target ~= src then msg(target, 'Invitation cancelled because the sender disconnected.', 'warning') end
        end
    end
    for owner, req in pairs(pendingControl) do
        if owner == src or req.from == src then
            pendingControl[owner] = nil
            if owner ~= src then msg(owner, 'Control request cancelled because the requester disconnected.', 'warning') end
        end
    end
end)
