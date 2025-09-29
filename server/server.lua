local models = lib.load('config.models')
local occupied = {}

lib.callback.register('mnr_sitanywhere:server:Occupy', function(source, netId, seat)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then
        return false
    end

    occupied[entity] = occupied[entity] or {}
    occupied[entity][seat] = source

    return true
end)

RegisterNetEvent('mnr_sitanywhere:server:Free', function(netId, seat)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then
        return
    end

    if not occupied[entity][seat] then
        return
    end

    if occupied[entity][seat] ~= src then
        return
    end

    occupied[entity][seat] = nil
    if next(occupied[entity]) then
        return
    end

    occupied[entity] = nil
    TriggerClientEvent('mnr_sitanywhere:client:Unregister', src, netId)
end)

lib.callback.register('mnr_sitanywhere:server:GetFree', function(source, netId, hash)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then
        return false
    end

    local max = models[hash].maxSeats
    occupied[entity] = occupied[entity] or {}

    for i = 1, max do
        if not occupied[entity][i] then
            return i
        end
    end

    return false
end)