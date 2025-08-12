local models = lib.load('config.config')
local state = require 'client.state'

local function cloneChair(entity)
    if not DoesEntityExist(entity) then
        return false, false
    end

    local hash = GetEntityModel(entity)
    lib.requestModel(hash)

    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local clone = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)

    if not DoesEntityExist(clone) then
        return false, false
    end

    SetEntityHeading(clone, heading)
    FreezeEntityPosition(clone, true)
    SetEntityVisible(entity, false, false)
    state:set('clonedEntity', clone)
    
    return true, clone
end

local function networkChair(entity, action)
    if not entity then
        return false, nil
    end

    local isLocal = NetworkGetEntityIsLocal(entity)
    if isLocal then
        NetworkRegisterEntityAsNetworked(entity)
    end

    Wait(100)

    local networked = NetworkGetEntityIsNetworked(entity)
    if networked then
        return true, entity, false
    else
        local success, clone = cloneChair(entity)
        
        return success, clone, true
    end
end

local function occupied(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local seat = lib.callback.await('mnr_sitanywhere:server:GetFree', 200, netId)

    return seat
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
            self:disable(true)
            state:set('sitting', false)
            state:set('entity', 0)
        end
    })

    lib.showTextUI(locale('textui.sit'))
    getup:disable(false)
end

RegisterNetEvent('mnr_sitanywhere:client:Sit', function(data)
    if not data.entity or data.entity == 0 then return end
    if state.sitting == true or state.entity or state.entity == data.entity then return end

    local success, entity, cloned = networkChair(data.entity, 'register')
    if not success then return end

    local seat = occupied(entity)
    if not seat then
        client.Notify(locale('notify.seat-occupied'), 'error')
        return
    end

    PlaySit(entity, seatID)
end)

RegisterNetEvent('mnr_sitanywhere:client:Unregister', function(netId)
    if GetInvokingResource() then return end

    if state.clonedEntity then
        SetEntityAsNoLongerNeeded(entity)
        SetEntityVisible(state.entity, true, false)
        NetworkUnregisterNetworkedEntity(entity)
        DeleteEntity(entity)
        
        state:set('clonedEntity', 0)
    else
        NetworkUnregisterNetworkedEntity(entity)
    end
end)

local targetModels = {}

for model in pairs(models) do
    targetModels[#targetModels+1] = model
end

target.AddModels(targetModels)

state:init()