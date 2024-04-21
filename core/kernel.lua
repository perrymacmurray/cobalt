local loadfile = ... -- we pass this function from init.lua

_G._OSVERSION = "COBALT 0.1 Dev"
_G.runlevel = 1

-- Override some functions
computer.runlevel = function()
    return _G.runlevel
end

local nativeShutdown = computer.shutdown
computer.shutdown = function(reboot)
    _G.runlevel = reboot and 6 or 0

    -- If we're able to sleep, attempt graceful shutdown
    if os.sleep then
        computer.pushSignal("SIGTERM")
        os.sleep(0.2)
        computer.pushSignal("SIGKILL")
        os.sleep(0.2)
    end

    nativeShutdown(reboot)
end

function os.sleep(timeout)
    checkArg(1, timeout, "number", "nil")
    local deadline = computer.uptime() + (timeout or 0)
    repeat
        computer.pullSignal(deadline - computer.uptime())
    until computer.uptime() >= deadline
end

computer.panic = function(err)
    computer.pushSignal("SIGKILL")

    if computer.runlevel() > 2 then -- 3+ runlevel means we have io/other important libraries
        io.stderr:write("KERNEL PANIC: " .. err)
    else
        local gpu = component.list("gpu", true)()
        if gpu then
            gpu = component.proxy(gpu)
            local w, h = gpu.getResolution()
            gpu.setForeground(0xFFA500)
            gpu.setBackground(0x000000)
            for i = 1, w, 3 do
                gpu.fill(i, 1, i, h, "K")
                gpu.fill(i + 1, 1, i + 1, h, "P")
                if (type(err) == "number" and err < 10) then
                    gpu.fill(i + 2, 1, i + 2, h, tostring(math.floor(err)))
                else
                    gpu.fill(i + 2, 1, i + 2, h, "!")
                end
            end
        end
    end

    _G.runlevel = 0
    while true do
        if os.sleep then
            os.sleep(100)
        end
    end
end

-- Bind GPU to screen
local w, h
local screen = component.list("screen", true)()
local gpu = screen and component.list("gpu", true)()
if gpu then
    gpu = component.proxy(gpu)
    if not gpu.getScreen() then
        gpu.bind(screen)
    end
    
    _G.boot_screen = gpu.getScreen()
    w, h = gpu.maxResolution()
    gpu.setResolution(w, h)
    gpu.setForeground(0xFFA500) -- orange phosphor color seems plesant for startup
    gpu.setBackground(0x000000)
    gpu.fill(1, 1, w, h, " ") -- write over screen
end

local y = 1
local function print(message)
    if gpu then
        gpu.set(1, y, "[" .. computer.uptime() .. "] " .. message)
        if y == h then
            gpu.copy(1, 2, w, h, 0, -1)
            gpu.fill(1, 1, w, h, " ")
        else
            y = y + 1
        end
    end
end

-- We've made it to the beginning of the initialization
_G.runlevel = 2
print("Initializing " .. _OSVERSION)
print("------------") -- this line is important enough to get two rows

local function dofile(file)
    print("Loading " .. file)
    local program, err = loadfile(file)
    if program then
        local result = table.pack(pcall(program))
        if result[1] then
            return table.unpack(result, 2, result.n)
        else
            computer.panic(result[2])
        end
    else
        computer.panic(err)
    end
end

-- Load core libraries
_G.filesystem = dofile("/core/filesystem.lua")
_G.shell = dofile("/core/shell.lua")

print("Mounting filesystem")
filesystem.mount(computer.getBootAddress(), "/")

_G.runlevel = 3
print("Finishing library initialization")
computer.pushSignal("SIGINIT")

_G.runlevel = 5