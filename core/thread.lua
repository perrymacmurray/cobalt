local thread = {}

Thread = {priority = 100, co = nil, id = 0}

local threadCount = 0
local function nextThreadID()
    threadCount = threadCount + 1
    return threadCount
end

function Thread:new(o, prio)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.priority = priority or 100
    o.co = nil
    o.id = nextThreadID()

    return o
end

function Thread:isAlive()
    if self.co == nil then return false end
    return coroutine.status(self.co) ~= "dead"
end

--TODO rework
function Thread:isKernel() return self.priority == 0 end

function thread.create(lambda)
    local t = Thread:new()
    t.co = coroutine.create(lambda)

    return t
end

return thread