function os.sleep(timeout)
    checkArg(1, timeout, "number", "nil")
    if kernel.scheduler.current_thread ~= nil then
        thread.sleep(timeout)
    else
        local deadline = computer.uptime() + (timeout or 0)
        repeat
            computer.pullSignal(deadline - computer.uptime())
        until computer.uptime() >= deadline
    end
end

os.log_file = nil
function os.log(message)
    if kernel.runlevel() < 2 then return end -- We can't log without a filesystem

    if type(message) ~= "string" then
        message = tostring(message)
    end

    if not os.log_file then
        os.log_file = fs.open("/log.txt", "a")

        if not os.log_file then kernel.panic("Cannot open file for logging!") end

        os.log_file:write("Opened file\n")

        -- local co = coroutine.create(function()
        --     while true do
        --         name, _ = computer.pullSignal()
        --         if name == "SIGKILL" then break end
        --     end
        --     os.log_file:write("Closing file\n")
        --     os.log_file:close()
        --     os.log_file = nil
        -- end)
        -- coroutine.resume(co)
    end

    os.log_file:write(message .. "\n")
end