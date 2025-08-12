local state = {}
state._index = state

function state:init()
    self.sitting = false
    self.entity = false
    self.clonedEntity = false
end

function state:set(key, value)
    self[key] = value
end

return state