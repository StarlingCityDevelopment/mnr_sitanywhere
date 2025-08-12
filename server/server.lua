---@description TEST WIP

local occupied = {}

RegisterNetEvent('mnr_sitanywhere:server:Occupy', function(netId, seatIndex)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then return end

    occupied[entity] = occupied[entity] or {}
    occupied[entity][seatIndex] = src
end)

RegisterNetEvent('mnr_sitanywhere:server:Free', function(netId, seatIndex)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then return end
    
    if not occupied[entity] then return end
    if occupied[entity][seatIndex] ~= src then return end

    occupied[entity][seatIndex] = nil
    
    if next(occupied[entity]) then return end
    
    occupied[entity] = nil
    TriggerClientEvent('mnr_sitanywhere:client:Unregister', src, netId)
end)

lib.callback.register('mnr_sitanywhere:server:GetFree', function(source, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then
        return false
    end

    local hash = GetEntityModel(entity)
    local max = models[hash].maxSeats
    occupied[entity] = occupied[entity] or {}
    
    for i = 1, max do
        if not occupied[entity][i] then
            return i
        end
    end
    
    return false
end)

---@description OLD PART (WIP MEANWHILE COMPAT)

RegisterNetEvent('mnr_sitanywhere:server:ModelRegistration', function(entityNetID, seat)
    local entity = NetworkGetEntityFromNetworkId(entityNetID)
    seat = math.max(seat, 0)
    if seat == 0 then
        occupied[entity] = nil
        TriggerClientEvent('mnr_sitanywhere:client:Unregister', -1, entityNetID)
    else
        occupied[entity] = seat
    end
end)

lib.callback.register('mnr_sitanywhere:server:GetModelSeats', function(source, entityNetID)
    local entity = NetworkGetEntityFromNetworkId(entityNetID)

    if not occupied[entity] then
        return 0
    else
        return occupied[entity]
    end
end)