local io = {}

function io.setGpu(gpuComponent)
    os.log("Changing IO gpu")
    if gpuComponent.getScreen() then
        io.gpu = gpuComponent

        io.w, io.h = io.gpu.getResolution()
        io.cur_w = 1
        io.cur_h = 1
        return true
    end

    return false
end

function io.clear()
    io.gpu.fill(1, 1, io.w, io.h, " ")
    io.cur_w = 1
    io.cur_h = 1
end

function io.erase(n)
    if io.cur_w == 1 then return end

    io.gpu.fill(io.cur_w - n, io.cur_h, io.cur_w, io.cur_h, " ")
    io.cur_w = io.cur_w - n
end

function io.bump()
    io.gpu.copy(1, 2, io.w, io.h, 0, -1)
    io.gpu.fill(1, io.h, io.w, io.h, " ")
    io.cur_h = io.h
end

function io.print(message)
    if io.cur_h > io.h then io.bump() end
    
    io.gpu.set(io.cur_w, io.cur_h, message)
    io.cur_w = io.cur_w + string.len(message)
end

function io.println(message)
    if type(message) ~= "string" then
        message = tostring(message)
    end

    --todo accomidate for long lines
    if io.cur_h > io.h then io.bump() end

    io.gpu.set(io.cur_w, io.cur_h, message)
    io.cur_h = io.cur_h + 1
    io.cur_w = 1
end

return io