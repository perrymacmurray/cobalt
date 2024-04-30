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
    words = {}
    for word in file:gmatch("%S+") do table.insert(words, word) end

    file = words[1]
    table.remove(words, 1)

    if file == "" then
        writeError("Must specify file name")
        return
    end

    -- Maybe add a PATH eventually or something
    if not file:match("%.lua$") then
        file = "/bin/" .. file .. ".lua"
    end

    if fs.exists(file) then
        os.log("Attempting to run file at " .. file)
        xpcall(require(file), function(message)
            writeError(message)
            writeError(debug.traceback())
        end, table.unpack(words))
    else
        writeError("File '" .. file .. "' does not exist")
    end
end

local function start()
    io.clear()
    local buffer = ""
    io.print("$ ")
    while true do
        local key = keyboard.getNextKey();
        if key == "BACK" then
            if buffer ~= "" then
                buffer = buffer:sub(1, -2)
                io.erase(1)
            end
        elseif key == "ENTER" then
            io.println("")
            runCommand(buffer)
            buffer = ""
            io.print("$ ")
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