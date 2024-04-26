local shell = {}

function shell.getShell()
    return thread.create(function()
        io.clear()
        while true do
            local key = keyboard.getNextKey();
            if key == "BACK" then
                io.erase(1)
            else
                io.print(key)
            end
        end
    end)
end

return shell