local state = {}
state.__index = state

function state:init()
    self.sitting = false
    self.entity = 0
    self.clone = false
    self.original = false
end

function state:set(key, value)
    self[key] = value
end

return state