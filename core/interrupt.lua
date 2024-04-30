-- No threads in this environment

local function getInput()
    local key = nil
    while true do
        ev, _, _, key = computer.pullSignal(0)
        if ev == "key_down" then break end
    end

    return keyboard.keysReverse[key]
end

function kernel.doInterrupt()
    -- Save monitor state
    local gpu = kernel.primary_gpu
    local w, h = gpu.getResolution()
    local fg = gpu.getForeground()
    local bg = gpu.getBackground()

    local prev = {}
    for x = 1, h + 1 do
        prev[x] = gpu.get(x, h)
    end

    if keyboard == nil then
        kernel.message("Keyboard not loaded - exiting")
        return
    end

    -- The disadvantage of doing it this way is we might lose events if interrupted
    -- But that's probably okay. Don't interrupt the scheduler if you want your events
    kernel.message("Awaiting input")
    local key = getInput()

    if key == "p" then -- *P*riority guarantee
        kernel.message("Scheduler guarantees priority " .. tostring(kernel.scheduler.guarantee))
    elseif key == "t" then -- number of *T*hreads
        kernel.message("Running " .. tostring(#(kernel.scheduler.threads)) .. " threads")
    elseif key == "c" then -- terminate the *C*urrently running base thread (I took this one from ctrl+c)
        kernel.baseThread.co = nil -- Set internal coroutine to nil (dangerous)
        
        local killed = false
        for i, tr in ipairs(kernel.scheduler.threads) do
            if tr.id == kernel.baseThread.id then
                table.remove(kernel.scheduler.threads, i)
                kernel.message("Killed thread " .. kernel.baseThread.id)
                killed = true
                break
            end
        end
        if not killed then kernel.message("Could not kill thread (already dead?)") end

        local tr = shell.getShell()
        kernel.baseThread = tr
        kernel.scheduler.addThread(tr)
    elseif key == "r" then -- *R*estart the current base thread
        kernel.baseThread:restart()
        kernel.message("Restarted thread " .. kernel.baseThread.id)
    end

    getInput() -- Wait before returning to scheduler

    -- Restore monitor state
    gpu.setForeground(fg)
    gpu.setBackground(bg)
    gpu.fill(1, h, w, h, " ")
    for x = 1, h + 1 do
        gpu.set(x, h, prev[x])
    end
end