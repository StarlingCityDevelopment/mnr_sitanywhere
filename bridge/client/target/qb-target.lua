---@diagnostic disable: duplicate-set-field, lowercase-global

if GetResourceState('qb-target') ~= 'started' then return end

target = {}

function target.AddModels(models)
    exports['qb-target']:AddTargetModel(models, {
        options = {
            {
                label = locale('target.sit'),
                icon = 'fa-solid fa-chair',
                canInteract = function(entity)
                    return DoesEntityExist(entity) and not cache.vehicle
                end,
                action = function(entity)
                    TriggerEvent('mnr_sitanywhere:client:Sit', { entity = entity })
                end,
            }
        },
        distance = 3.0,
    })
end