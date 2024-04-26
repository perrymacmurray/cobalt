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
    io.gpu.fill(io.cur_w - n, io.cur_h, io.cur_w, io.cur_h, " ")
    io.cur_w = io.cur_w - n
end

function io.print(message)
    local max_w, max_h = io.gpu.maxResolution()

    io.gpu.set(io.cur_w, io.cur_h, message)
    io.cur_w = io.cur_w + string.len(message)
end

function io.println(message)
    if type(message) ~= "string" then
        message = tostring(message)
    end

    local max_w, max_h = io.gpu.maxResolution()

    --todo accomidate for long lines
    if io.cur_h > max_h then
        io.gpu.copy(1, 2, w, h, 0, -1)
        io.gpu.fill(1, h, w, h, " ")
        io.cur_h = max_h
    end
    io.gpu.set(io.cur_w, io.cur_h, message)
    io.cur_h = io.cur_h + 1
end

return io