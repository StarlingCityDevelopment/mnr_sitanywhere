---@diagnostic disable: duplicate-set-field, lowercase-global

if GetResourceState('ox_target') ~= 'started' then return end

local state = require 'client.state'

target = {}

function target.AddModels(models)
    exports.ox_target:addModel(models, {
        {
            label = locale('target.sit'),
            name = 'mnr_sitanywhere:sit',
            icon = 'fa-solid fa-chair',
            canInteract = function(entity)
                return DoesEntityExist(entity) and not state.sitting
            end,
            onSelect = function(data)
                TriggerEvent('mnr_sitanywhere:client:Sit', data)
            end,
        }
    })
end