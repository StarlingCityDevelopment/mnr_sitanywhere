local state = {}
state.__index = state

function state:init()
    self.sitting = false
    self.entity = 0
    self.clone = 0
    self.original = 0
end

function state:set(key, value)
    self[key] = value
end

return state