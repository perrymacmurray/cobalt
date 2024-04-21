local shell = {}

function shell.getShell()
    if io then
        io.clear()
        io.println("Everything works so far")
    end
    os.sleep(10)
    
    return 0
end

return shell