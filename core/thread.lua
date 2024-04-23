local thread = {}

--- Thread
Thread = {priority = 100, co = nil, id = 0, sleep = 0}

local threadCount = 0
local function nextThreadID()
    threadCount = threadCount + 1
    return threadCount
end

function Thread:new(o, prio)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.id = nextThreadID() -- Thread ID, should be unique
    o.co = nil -- Internal coroutine
    o.priority = priority or 100 -- Thread priority, lower number = more important
    o.sleep = 0 -- How long the thread has said it's okay to sleep for

    return o
end

function Thread:isAlive()
    if self.co == nil then return false end
    return coroutine.status(self.co) ~= "dead"
end

function Thread:isReady()
    if not self:isAlive() then return false end
    if self.sleep > 0 then return false end
    return true
end

function Thread:run()
    if not self:isReady() then return false end
    local status, retval = coroutine.resume(self.co)
    if not status then return false, retval end

    if type(retval) == "number" then self.sleep = retval end
    return true, nil
end
--- End Thread

function thread.create(lambda)
    local t = Thread:new()
    t.co = coroutine.create(lambda)

    return t
end

function thread.sleep(timeout)
    if kernel.scheduler.current_thread == nil then return false end
    checkArg(1, timeout, "number", "nil")

    local deadline = computer.uptime() + (timeout or 0)
    repeat
        coroutine.yield(deadline - computer.uptime())
    until computer.uptime() >= deadline

    return true
end

-- Return control to scheduler, but resume ASAP
function thread.yield()
    if kernel.scheduler.current_thread == nil then return false end
    coroutine.yield(0)
    return true
end

return thread