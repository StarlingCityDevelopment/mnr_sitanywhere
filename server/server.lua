Seats = {}

RegisterNetEvent('mnr_sitanywhere:server:ModelRegistration', function(entityNetID, seat)
    local entity = NetworkGetEntityFromNetworkId(entityNetID)
    seat = math.max(seat, 0)
    if seat == 0 then
        Seats[entity] = nil
        TriggerClientEvent('mnr_sitanywhere:client:Unregister', -1, entityNetID)
    else
        Seats[entity] = seat
    end
end)

lib.callback.register('mnr_sitanywhere:server:GetModelSeats', function(source, entityNetID)
    local entity = NetworkGetEntityFromNetworkId(entityNetID)

    if not Seats[entity] then
        return 0
    else
        return Seats[entity]
    end
end)