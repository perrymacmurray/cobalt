function kernel.doInterrupt()
    --TODO
    --no threads in this environment

    local gpu = kernel.primary_gpu
    gpu.setBackground(0xFF0000)
    gpu.set(70, 0, tostring(kernel.scheduler.guarantee))
    gpu.setBackground(0x000000)
end