local scheduler = {}

scheduler.threads = {}
local threads = scheduler.threads

function scheduler.addThread(thread)
    -- TODO make this safe
    table.insert(threads, thread)
end

local function threadCompare(a, b)
    if a.sleep == b.sleep then
        return a.priority < b.priority
    end

    -- Otherwise, use time
    return a.sleep < b.sleep
end

function scheduler.begin()
    local lastTime = computer.uptime()
    while kernel.runlevel() == 5 do
        computer.pullSignal(0) -- Yield to underlying OpenComputers machine

        local deadThreads = {}
        for i, tr in ipairs(threads) do
            scheduler.current_thread = tr.id
            local ok, err = tr:run()
            scheduler.current_thread = nil

            if not ok then
                if not tr:isAlive() then
                    table.insert(deadThreads, i) -- Store indices in threads table
                end
            end
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

        -- Reorder priorities
        table.sort(threads, threadCompare)
    end
end

return scheduler