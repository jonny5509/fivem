-- Server validation and broadcast for Self Control roadside-prop impacts.
local allowedModels = {}
for _, modelName in ipairs(Config.Bollards.Models or {}) do
    allowedModels[GetHashKey(modelName)] = true
end

local recentHits = {}
RegisterNetEvent('xtoys:reportSelfControlBollardHit', function(x, y, z, modelHash)
    local src = source
    if not Config.Bollards.Enabled
        or type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end

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

    TriggerClientEvent('xtoys:selfControlBollardHit', -1)
    for hitKey, hitTime in pairs(recentHits) do
        if now - hitTime > 10000 then recentHits[hitKey] = nil end
    end
end)
