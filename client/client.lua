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
    state:set('original', entity)
    state:set('clone', clone)

    return true, clone
end

local function networkChair(entity)
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
    local hash = GetEntityModel(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local seat = lib.callback.await('mnr_sitanywhere:server:GetFree', 200, netId, hash)

    return seat
end

local function rotateOffset(offset, heading)
    local rad = math.rad(heading)
    local cosH = math.cos(rad)
    local sinH = math.sin(rad)

    local newX = offset.x * cosH - offset.y * sinH
    local newY = offset.x * sinH + offset.y * cosH

    return vec3(newX, newY, offset.z)
end

local function playSit(entity, seat)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local taken = lib.callback.await('mnr_sitanywhere:server:Occupy', false, netId, seat)
    if not taken then
        return
    end

    state:set('sitting', true)
    state:set('entity', entity)

    local hash = GetEntityModel(entity)
    local model = models[hash]
    local seatOffset = model.seats[seat]
    local seatCoords = GetEntityCoords(entity)
    local seatHeading = GetEntityHeading(entity)
    local rotatedOffset = rotateOffset(seatOffset, seatHeading)
    local coords = seatCoords + rotatedOffset
    local heading = seatHeading + seatOffset.w

    if not model.scenario then 
        return
    end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, true, false, false, false)
    TaskStartScenarioAtPosition(cache.ped, model.scenario, coords.x, coords.y, coords.z, heading, 0, true, true)

    local keybind = lib.addKeybind({
        name = 'mnr_sitanywhere:keybind:get_up',
        description = 'Used for get up from a seat',
        defaultKey = 'E',
        disabled = true,
        onReleased = function(self)
            TriggerServerEvent('mnr_sitanywhere:server:Free', netId, seat)
            lib.hideTextUI()
            self:disable(true)
            ClearPedTasks(cache.ped)
            state:set('sitting', false)
            state:set('entity', 0)
            if state.original then
                SetEntityVisible(state.original, true, false)
                state:set('original', false)
            end
        end
    })

    lib.showTextUI(locale('textui.sit'))
    keybind:disable(false)
end

RegisterNetEvent('mnr_sitanywhere:client:Sit', function(data)
    if not DoesEntityExist(data.entity) then
        return
    end
    
    if state.sitting or state.entity == data.entity then
        return
    end

    local success, entity, cloned = networkChair(data.entity)
    if not success then
        return
    end

    local seat = occupied(entity)
    if not seat then
        client.Notify(locale('notify.seat-occupied'), 'error')
        return
    end

    playSit(entity, seat)
end)

RegisterNetEvent('mnr_sitanywhere:client:Unregister', function(netId)
    if GetInvokingResource() then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if state.clone and state.clone == entity then
        SetEntityAsNoLongerNeeded(entity)
        NetworkUnregisterNetworkedEntity(entity)
        DeleteEntity(entity)
        state:set('original', false)
        state:set('clone', false)
    else
        NetworkUnregisterNetworkedEntity(entity)
    end
end)

local targetModels = {}

for targetModel in pairs(models) do
    targetModels[#targetModels+1] = targetModel
end

target.AddModels(targetModels)

state:init()