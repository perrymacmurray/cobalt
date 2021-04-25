-- Update settings to configure embedded mode

_G.embeddedinetupdate = false -- Whether or not to attempt updating the embedded program via the Internet. Requires Internet card
_G.embeddedprogramloc = "" -- Set web address of embedded program.
_G.embeddedcleandirectory = false -- Clean entire /embed folder every restart

--------------------------------------------------------------
local component = require("component")
local fs = require("filesystem")
local shell = require("shell")
local inet = require("internet")
local gpu = component.gpu

w, h = gpu.maxResolution()
gpu.setResolution(w, h)

if embeddedinetupdate then
    gpu.setBackground(0xFFFFFF)
    if gpu.getDepth() == 1 then
        gpu.setForeground(0x000000)
    else
        gpu.setForeground(0x0047AB)
    end
    gpu.fill(1, 1, w, h, " ")

    if not component.isAvailable("internet") then
        print("COBALT requires an Internet card to run in embedded mode. Resetting COBALT runtype...")
        fs.remove("/etc/cobalt/runtype.lua")
        shell.execute("cp /etc/cobalt/runtype-default.lua /etc/cobalt/runtype.lua")
        os.sleep(5)
        shell.execute("reboot")
    end

    local logoScreenHeight = 9

    gpu.fill(1, 1, w, logoScreenHeight, "█")
    gpu.set(1, 2, "█████     ██     ██    ███     ██ ██████     █████")
    gpu.set(1, 3, "█████ ██████ ███ ██ ██  ██ ███ ██ ████████ ███████")
    gpu.set(1, 4, "█████ ██████ ███ ██    ███     ██ ████████ ███████")
    gpu.set(1, 5, "█████ ██████ ███ ██ ██  ██ ███ ██ ████████ ███████")
    gpu.set(1, 6, "█████     ██     ██    ███ ███ ██     ████ ███████")
    gpu.set(1, 8, "█████                EMBEDDED                █████")

    gpu.set(1, 10, "Downloading embedded program from Internet...")

    if embeddedcleandirectory then
        gpu.set(1, 11, "Cleaning up /embed/ directory...")
        fs.remove("/embed")
        fs.makeDirectory("/embed")
    end

    shell.execute("wget -Qf " .. embeddedprogramloc .. " /embed/main.lua")
end

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")
--------------------------------------------------------------

os.execute("/embed/main.lua")