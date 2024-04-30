local thread = {}

--- Thread
Thread = {priority = 10, grief = 0, func = nil, co = nil, id = 0, sleep = 0, waiting = false, event = nil}

local threadCount = 0
local function nextThreadID()
    threadCount = threadCount + 1
    return threadCount
end

function Thread:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.id = nextThreadID() -- Thread ID, should be unique
    o.func = nil -- Function called for coroutine
    o.co = nil -- Internal coroutine
    o.priority = 10 -- Thread priority, lower number = more important
    o.grief = 0 -- Used by the scheduler alongside priority. Kind of like Linux's Nice, but reversed and volatile
    o.sleep = 0 -- How long the thread has said it's okay to sleep for
    o.waiting = false -- If the thread is currently waiting
    o.event = nil -- Used by thread.wait(), represents a pending event for the thread to process

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

    local waitFor = nil
    if type(retval) == "number" then
        self.sleep = retval
    elseif type(retval) == "string" then
        waitFor = retval
    end

    return true, waitFor
end

function Thread:restart()
    self.co = coroutine.create(self.func)
    self.sleep = 0
    self.waiting = false
    self.event = nil
end
--- End Thread

function thread.create(lambda, prio)
    local t = Thread:new()
    t.co = coroutine.create(lambda)
    t.func = lambda
    if (prio ~= nil) then t.priority = prio end

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

-- Waits for the given event name, indefinitely
function thread.wait(eventName)
    if kernel.scheduler.current_thread == nil then return false end
    while true do
        kernel.scheduler.current_thread.waiting = true
        coroutine.yield(eventName)

        local event = kernel.scheduler.current_thread.event
        if event ~= nil then
            kernel.scheduler.current_thread.event = nil
            kernel.scheduler.current_thread.waiting = false
            return true, table.unpack(event)
        end
    end
end

return thread