---@diagnostic disable: duplicate-set-field, lowercase-global

if GetResourceState('ox_target') ~= 'started' then return end

target = {}

function target.AddModels(models)
    exports.ox_target:addModel(models, {
        {
            label = locale('target_sit'),
            name = 'mnr_sitanywhere:sit',
            icon = 'fa-solid fa-chair',
            distance = 3.0,
            canInteract = function(entity)
                return DoesEntityExist(entity) and not cache.vehicle
            end,
            onSelect = function(data)
                TriggerEvent('mnr_sitanywhere:client:Sit', data)
            end,
        }
    })
end