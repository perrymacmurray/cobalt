local component = require("component");
local fs = require("filesystem");

local computer = component.computer;

if (!fs.exists("/etc/cobalt/uid")) then
    print("Cobalt is not configured properly, and will not run.")
    print("Run the cobalt command for setup")
    computer.beep(1000, 0.5);
    computer.beep(2000, 0.5);
    computer.beep(1000, 0.5);
    computer.beep(2000, 5);
end

--todo