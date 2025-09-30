local state = require 'client.state'
local config = require 'config.config'
local models = require 'config.models'
local actions = require 'config.actions'

local function rotateOffset(offset, heading)
    local rad = math.rad(heading)
    local cosH = math.cos(rad)
    local sinH = math.sin(rad)

    local newX = offset.x * cosH - offset.y * sinH
    local newY = offset.x * sinH + offset.y * cosH

    return vec3(newX, newY, offset.z)
end

local function execAction(action, coords, heading)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, true, false, false, false)

    local actionData = actions[action]
    if actionData.type == 'scenario' then
        TaskStartScenarioAtPosition(cache.ped, actionData.scenario, coords.x, coords.y, coords.z, heading, 0, true, true)
    elseif actionData.type == 'anim' then
        lib.requestAnimDict(actionData.dict)
        TaskPlayAnim(cache.ped, actionData.dict, actionData.name, 8.0, -8.0, -1, 1, 0, false, false, false)
        RemoveAnimDict(actionData.dict)
    end
end

local function playSit(entity, seat)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local taken = lib.callback.await('mnr_sitanywhere:server:Occupy', false, netId, seat)
    if not taken then return end

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

    if not model.action then return end
    execAction(model.action, coords, heading)

    local keybind = lib.addKeybind({
        name = 'mnr_sitanywhere:keybind:get_up',
        description = 'mnr_sitanywhere',
        defaultKey = config.key,
        disabled = true,
        onReleased = function(self)
            TriggerServerEvent('mnr_sitanywhere:server:Free', netId, seat)
            lib.hideTextUI()
            self:disable(true)
            ClearPedTasks(cache.ped)
            state:set('sitting', false)
            state:set('entity', 0)
        end
    })

    lib.showTextUI(locale('textui_sit', config.key))
    keybind:disable(false)
end

AddEventHandler('mnr_sitanywhere:client:Sit', function(data)
    if state.sitting then return end
    if not DoesEntityExist(data.entity) then return end

    if not NetworkGetEntityIsNetworked(data.entity) then
        NetworkRegisterEntityAsNetworked(data.entity)
    end

    Wait(100)

    if not NetworkGetEntityIsNetworked(data.entity) then
        print('^3[WARNING]: Chair can\'t be networked, if is a supported creator it will be soon made available.^0')
        return
    end

    local hash = GetEntityModel(data.entity)
    local netId = NetworkGetNetworkIdFromEntity(data.entity)
    local seat = lib.callback.await('mnr_sitanywhere:server:GetFree', 200, netId, hash)
    if not seat then
        client.Notify(locale('notify_seat_occupied'), 'error')
        return
    end

    playSit(data.entity, seat)
end)

RegisterNetEvent('mnr_sitanywhere:client:Unregister', function(netId)
    if GetInvokingResource() then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    NetworkUnregisterNetworkedEntity(entity)
end)

local targetModels = {}

for targetModel in pairs(models) do
    targetModels[#targetModels+1] = targetModel
end

target.AddModels(targetModels)

state:init()