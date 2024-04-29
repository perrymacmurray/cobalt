local shell = {}

local function start()
    io.clear()
    while true do
        local key = keyboard.getNextKey();
        if key == "BACK" then
            io.erase(1)
        elseif key == "ENTER" then
            io.println("")
        else
            io.print(key)
        end
    end
end

function shell.getShell()
    return thread.create(start, 8)
end

return shell