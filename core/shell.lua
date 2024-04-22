local shell = {}

function shell.getShell()
    return thread.create(function()
        io.clear()
        while true do
            io.println("Everything works so far")
            os.sleep(2)
        end
    end)
end

return shell