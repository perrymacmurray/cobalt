local shell = {}

local function getShell()
    io.stdout:write("Everything works so far")
    os.sleep(10)
    
    return 0
end

shell.getShell = getShell

return shell