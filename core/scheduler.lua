local scheduler = {}

-- Eventually I want the scheduler to use linux-like priorities, 0-100
-- For now, I'm gonna do "normal" and "kernel" threads
-- Normal threads will run round robin, with all kernel threads running RR in between
-- I am confident this will be less than ideal. But it should work until I program a
-- better scheduler.

scheduler.threads = {}
local threads = scheduler.threads

function scheduler.begin()
    while kernel.runlevel() == 5 do
        for _, tr in ipairs(threads) do
            coroutine.resume(tr.co)
        end
        computer.pullSignal(0) -- Yield to underlying OpenComputers machine
    end
end

return scheduler