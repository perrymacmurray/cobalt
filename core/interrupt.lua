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