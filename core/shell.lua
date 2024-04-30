local shell = {}

local function magiclines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

local function writeError(message)
    local fg = kernel.primary_gpu.getForeground()
    kernel.primary_gpu.setForeground(0xFF0000)

    for s in magiclines(message) do
        io.println(s)
    end

    kernel.primary_gpu.setForeground(fg)
end

local function runCommand(file)
    if file == "" then
        writeError("Must specify file name")
        return
    end

    if fs.exists(file) then
        os.log("Attempting to run file at " .. file)
        xpcall(require(file), function()
            writeError(debug.traceback())
        end)
    else
        writeError("File " .. file .. " does not exist")
    end
end

local function start()
    io.clear()
    local buffer = ""
    while true do
        local key = keyboard.getNextKey();
        if key == "BACK" then
            io.erase(1)
            buffer = buffer:sub(1, -2)
        elseif key == "ENTER" then
            io.println("")
            runCommand(buffer)
            buffer = ""
        else
            io.print(key)
            buffer = buffer .. key
        end
    end
end

function shell.getShell()
    return thread.create(start, 8)
end

return shell