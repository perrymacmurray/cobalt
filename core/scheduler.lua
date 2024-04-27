local scheduler = {}

scheduler.guarantee = 10

scheduler.threads = {}
scheduler.callbacks = {}
local threads = scheduler.threads

function scheduler.addThread(thread)
    -- TODO make this safe
    table.insert(threads, thread)
end

local function runThread(tr)
    scheduler.current_thread = tr
    local ok, extra = tr:run()
    scheduler.current_thread = nil
    return ok, extra
end

local function threadCompare(a, b)
    if a.waiting then return false end -- Guarantee waiting threads end up in back

    if a.sleep == b.sleep then
        return a.priority < b.priority
    end

    -- Otherwise, use time
    return a.sleep < b.sleep
end

local function addCallback(tr, eventName)
    if scheduler.callbacks[eventName] == nil then
        scheduler.callbacks[eventName] = {}
    end

    table.insert(scheduler.callbacks[eventName], tr)
end

local function doCallbacks(event)
    -- For loops don't like it when iterating over nil
    if scheduler.callbacks[event[1]] == nil then return end

    for _, tr in ipairs(scheduler.callbacks[event[1]]) do
        tr.event = event
    end

    local cbThreads = scheduler.callbacks[event[1]]
    scheduler.callbacks[event[1]] = {}
    for _, tr in ipairs(cbThreads) do
        local ok, extra = runThread(tr)

        -- We have to handle adding callbacks again here, which is kind of annoying
        if ok then
            if extra ~= nil then addCallback(tr, extra) end
        end
    end
end

function scheduler.begin()
    local lastTime = computer.uptime()
    while kernel.runlevel() == 5 do
        local deadThreads = {}
        for i, tr in ipairs(threads) do
            -- Skip threads which are waiting/unguaranteed
            if tr.waiting then goto ThreadEnd end

            if tr.priority > scheduler.guarantee then
                local defecit = tr.priority - scheduler.guarantee
                if tr.grief >= defecit then
                    grief = grief - defecit
                    if grief < 0 then grief = 0 end
                else
                    grief = grief + 2
                    goto ThreadEnd
                end
            end

            -- Thread gets to run this cycle :)
            do
                local ok, extra = runThread(tr)
            
                if ok then
                    if extra ~= nil then
                        addCallback(tr, extra) -- Thread is waiting for event
                    end
                else
                    if not tr:isAlive() then
                        os.log("Thread " .. tr.id .. " died: " .. tostring(extra))
                        table.insert(deadThreads, i) -- Store indices in threads table
                    end
                end
            end

            ::ThreadEnd::
            local event = {computer.pullSignal(0)} -- Yield to underlying OpenComputers machine
            if event ~= nil and event[1] ~= nil then doCallbacks(event) end
        end

        -- Clean up dead threads
        for _, i in ipairs(deadThreads) do table.remove(threads, i) end 

        -- Update sleep times
        local curTime = computer.uptime()
        local delta = curTime - lastTime
        for _, tr in ipairs(threads) do
            tr.sleep = tr.sleep - delta
            if tr.sleep < 0 then tr.sleep = 0 end
        end
        lastTime = curTime

        -- Change guarantee if necessary
        if delta > 0.15 then
            -- I'm not sure what the best way to do this is.
            -- Maybe a rolling average?
            if scheduler.guarantee > 1 then
                scheduler.guarantee = scheduler.guarantee - 1
                os.log("Set scheduler guarantee to " .. scheduler.guarantee)
            end
        end

        -- Reorder priorities
        table.sort(threads, threadCompare)

        -- Grab kernel interrupt
        if keyboard ~= nil then
            if keyboard.isCtrlDown() and keyboard.isKeyDown(keyboard.keys.k) then
                kernel.doInterrupt()
            end
        end

        if #threads == 0 then kernel.panic("All threads have died!") end
    end
end

return scheduler