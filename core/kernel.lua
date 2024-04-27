local loadfile = ... -- we pass this function from init.lua

_G._OSVERSION = "COBALT 0.4 Dev"
_G.runlevel = 1

_G.kernel = {}

-- Override some functions
function kernel.runlevel()
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

kernel.panic = function(err)
    -- Write before sigkill to make sure filesystem is still working (hopefully)
    if os.log then os.log("KERNEL PANIC: " .. err) end

    computer.pushSignal("SIGKILL")

    local gpu = component.list("gpu", true)()
    if gpu then
        gpu = component.proxy(gpu)
        local w, h = gpu.getResolution()
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0xFF0000)
        gpu.set(1, h, "KERNEL PANIC: " .. err)
    end

    _G.runlevel = 0
    error(err)
end

kernel.message = function(message)
    message = "KERNEL: " .. message
    if os.log then os.log(message) end

    local gpu = component.list("gpu", true)()
    if gpu then
        gpu = component.proxy(gpu)
        local w, h = gpu.getResolution()

        gpu.setForeground(0x000000)
        gpu.setBackground(0xFFA500)
        gpu.fill(1, h, w, h, " ")
        gpu.set(1, h, message)
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
    
    kernel.primary_gpu = gpu
    w, h = gpu.maxResolution()
    gpu.setResolution(w, h)
    gpu.setBackground(0x000000)
    gpu.fill(1, 1, w, h, " ") -- write over screen
end

local y = 1
local function print(message)
    if os.log then os.log(message) end
    if gpu then
        -- fancy colors by runlevel
        if runlevel == 1 then gpu.setForeground(0xAB0202) end
        if runlevel == 2 then gpu.setForeground(0xFFA500) end
        if runlevel == 3 then gpu.setForeground(0xE3CC20) end
        if runlevel == 4 then gpu.setForeground(0x02AD10) end

        gpu.set(1, y, "[" .. computer.uptime() .. "] " .. message)
        if y == h then
            gpu.copy(1, 2, w, h, 0, -1)
            gpu.fill(1, h, w, h, " ")
        else
            y = y + 1
        end
    end
end

-- We've made it to the beginning of the initialization
print("Initializing " .. _OSVERSION)

local function dofile(file)
    print("Loading " .. file)
    local program, err = loadfile(file)
    if program then
        local result = table.pack(pcall(program))
        if result[1] then
            return table.unpack(result, 2, result.n)
        else
            kernel.panic(result[2])
        end
    else
        kernel.panic(err)
    end
end

-- Load core libraries
dofile("/core/os.lua")
_G.fs = dofile("/core/fs.lua")

print("Mounting filesystem")
fs.mount(computer.getBootAddress(), "/")

-- Run level 2: OS core loaded, filesystem loaded, boot drive mounted, logging enabled
_G.runlevel = 2

print("Seeding random")
math.randomseed(os.time())

dofile("/core/interrupt.lua") -- Kernel interrupt
kernel.scheduler = dofile("/core/scheduler.lua")
_G.thread = dofile("/core/thread.lua")
_G.io = dofile("/core/io.lua")

-- Run level 3: IO and other low level libraries loaded
_G.runlevel = 3

_G.keyboard = dofile("/core/keyboard.lua")
kernel.scheduler.addThread(keyboard.getDownListenerThread())
kernel.scheduler.addThread(keyboard.getUpListenerThread())

_G.shell = dofile("/core/shell.lua")

-- Run level 4: All core libraries loaded
_G.runlevel = 4

print("Finishing library initialization")
computer.pushSignal("SIGINIT")
io.setGpu(kernel.primary_gpu)

-- Run level 5: Fully loaded
_G.runlevel = 5

if gpu then gpu.setForeground(0xFFFFFF) end

kernel.scheduler.addThread(shell.getShell())