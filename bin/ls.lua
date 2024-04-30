local arg = ...

if arg == nil then arg = "/" end

for node in fs.list(arg) do
    io.println(node)
end