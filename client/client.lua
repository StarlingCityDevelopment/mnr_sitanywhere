local models = lib.load('config.config')
local state = require 'client.state'

local function CloneAndNetworkEntity(entity)
    if not DoesEntityExist(entity) then
        return nil, nil
    end

    local modelHash = GetEntityModel(entity)
    lib.requestModel(modelHash)

    local entityCoords = GetEntityCoords(entity)
    local entityHeading = GetEntityHeading(entity)
    local clonedEntity = CreateObject(modelHash, entityCoords.x, entityCoords.y, entityCoords.z, true, true, false)
    if not DoesEntityExist(clonedEntity) then
        return nil, nil
    end

    SetEntityHeading(clonedEntity, entityHeading)
    FreezeEntityPosition(clonedEntity, true)

    NetworkRegisterEntityAsNetworked(clonedEntity)

    SetEntityVisible(entity, false, false)

    state:set('clonedEntity', clonedEntity)
    return clonedEntity
end

local function NetworkChair(entity, action)
    if not entity then
        return false, nil
    end

    if action == 'register' then
        local isLocal = NetworkGetEntityIsLocal(entity)
        if isLocal then
            NetworkRegisterEntityAsNetworked(entity)
        end

        Wait(100)

        local isNetworked = NetworkGetEntityIsNetworked(entity)
        if isNetworked then
            return true, entity
        else
            local clonedEntity = CloneAndNetworkEntity(entity)
            if clonedEntity then
                return true, clonedEntity
            else
                return false, nil
            end
        end
    end

    if action == 'unregister' then
        if state.clonedEntity ~= 0 then
            SetEntityAsNoLongerNeeded(entity)
            SetEntityVisible(state.entity, true, false)
            NetworkUnregisterNetworkedEntity(entity)
            DeleteEntity(entity)
            
            state:set('clonedEntity', 0)
        else
            NetworkUnregisterNetworkedEntity(entity)
        end
    end
end

local function IsSeatOccupied(entity)
    local modelHash = GetEntityModel(entity)
    local modelData = models[modelHash]
    if not modelData then return end

    local entityNetID = NetworkGetNetworkIdFromEntity(entity)
    local seats = lib.callback.await('mnr_sitanywhere:server:GetModelSeats', 200, entityNetID)

    if seats == 0 then
        return false, 1
    end

    if seats == modelData.maxSeats then
        return true, false
    else
        return false, seats + 1
    end
end

local function RotateOffset(offset, heading)
    local rad = math.rad(heading)
    local cosH = math.cos(rad)
    local sinH = math.sin(rad)

    local newX = offset.x * cosH - offset.y * sinH
    local newY = offset.x * sinH + offset.y * cosH

    return vec3(newX, newY, offset.z)
end

local function PlaySit(entity, seatID)
    state:set('sitting', true)
    state:set('entity', entity)

    local entityNetID = NetworkGetNetworkIdFromEntity(entity)
    TriggerServerEvent('mnr_sitanywhere:server:ModelRegistration', entityNetID, seatID)

    local playerPed = cache.ped or PlayerPedId()
    local modelHash = GetEntityModel(entity)
    local modelData = models[modelHash]

    local entityCoords = GetEntityCoords(entity)
    local entityHeading = GetEntityHeading(entity)
    local seatOffset = modelData.seats[seatID]
    local rotatedOffset = RotateOffset(seatOffset, entityHeading)
    local position = entityCoords + rotatedOffset
    local heading = entityHeading + seatOffset.w
    SetEntityCoords(playerPed, position.x, position.y, position.z, true, false, false, false)

    if modelData.anim.scenario then
        TaskStartScenarioAtPosition(playerPed, modelData.anim.scenario, position.x, position.y, position.z, heading, 0, true, true)
    end

    local getup = lib.addKeybind({
        name = 'get-up',
        description = 'Used for get up from a seat',
        defaultKey = 'E',
        disabled = true,
        onReleased = function(self)
            lib.hideTextUI()
            ClearPedTasks(playerPed)
            seatID -= 1
            TriggerServerEvent('mnr_sitanywhere:server:ModelRegistration', entityNetID, seatID)
            if seatID == 0 then
                NetworkChair(entity, 'unregister')
            end
            self:disable(true)
            state:set('sitting', false)
            state:set('entity', 0)
        end
    })

    lib.showTextUI(locale('textui.sit'))
    getup:disable(false)
end

RegisterNetEvent('mnr_sitanywhere:client:Sit', function(data)
    if not data.entity then return end
    if state.sitting == true and state.entity ~= 0 or state.entity == data.entity then return end

    local networkSuccess, entity = NetworkChair(data.entity, 'register')
    if not networkSuccess then return end

    local seatOccupied, seatID = IsSeatOccupied(entity)
    if seatOccupied then
        return client.Notify(locale('notify.seat-occupied'), 'error')
    end

    PlaySit(entity, seatID)
end)


local targetModels = {}

for model in pairs(models) do
    targetModels[#targetModels+1] = model
end

target.AddModels(targetModels)

state:init()