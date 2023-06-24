local fs = require("filesystem");
local component = require("component");
local term = require("term");

local internet = component.internet;

fs.makeDirectory("/etc/cobalt");

term.clear();
      ___           ___           ___           ___           ___       ___     
print("     /\\  \\         /\\  \\         /\\  \\         /\\  \\         /\\__\\     /\\  \\    ");
print("    /::\\  \\       /::\\  \\       /::\\  \\       /::\\  \\       /:/  /     \\:\\  \\   ");
print("   /:/\\:\\  \\     /:/\\:\\  \\     /:/\\:\\  \\     /:/\\:\\  \\     /:/  /       \\:\\  \\  ");
print("  /:/  \\:\\  \\   /:/  \\:\\  \\   /::\\~\\:\\__\\   /::\\~\\:\\  \\   /:/  /        /::\\  \\ ");
print(" /:/__/ \\:\\__\\ /:/__/ \\:\\__\\ /:/\\:\\ \\:|__| /:/\\:\\ \\:\\__\\ /:/__/        /:/\\:\\__\\");
print(" \\:\\  \\  \\/__/ \\:\\  \\ /:/  / \\:\\~\\:\\/:/  / \\/__\\:\\/:/  / \\:\\  \\       /:/  \\/__/");
print("  \\:\\  \\        \\:\\  /:/  /   \\:\\ \\::/  /       \\::/  /   \\:\\  \\     /:/  /     ");
print("   \\:\\  \\        \\:\\/:/  /     \\:\\/:/  /        /:/  /     \\:\\  \\    \\/__/      ");
print("    \\:\\__\\        \\::/  /       \\::/__/        /:/  /       \\:\\__\\              ");
print("     \\/__/         \\/__/         ~~            \\/__/         \\/__/              ");

print("Welcome to the Cobalt setup!");

if (not fs.exists("/etc/cobalt/uid")) then
    print("");
    print("This computer currently does not have a UID.")
    print("Please enter the desired UID, or press enter to generate a new one")
    local uid = io.read();
    if (uid == "" or uid == nil) then
        print("Generating UID...");
        uid = require("uuid").next();
        print("UUID:", uid);
    end
    local file = io.open("/etc/cobalt/uid", "w");
    file:write(uid);
    file:close();
end

if (internet ~= nil) then
    print("");
    print("Cobalt allows computers to communicate with a central server through HTTPS.");
    print("If you have such a server, please enter the URL to send these requests to (or, nothing to make no changes)");
    local server = io.read();
    if (server ~= "" and server ~= nil) then
        local file = io.open("/etc/cobalt/server", "w");
        file:write(server);
        file:close();

        print("");
        print("Some servers may require a token to be sent with requests, for either security or to differentiate between worlds/networks.");
        print("If you have one of these tokens, please enter it now. Otherwise, if not applicable, LEAVE THIS BLANK");
        local token = io.read();
        if (token ~= "" and token ~= nil) then
            local file = io.open("/etc/cobalt/token", "w");
            file:write(token);
            file:close();
        end

        print("");
        print("This computer will periodically fetch data from the central server. By default, it does this once per minute.");
        print("If you would like this to be more frequent, please enter the amount of time to wait between requests below (in seconds)");
        local frequency = io.read();
        if (typeof(frequency) == "number" and math.floor(frequency) == frequency and frequency > 0) then
            local file = io.open("/etc/cobalt/frequency", "w");
            file:write(frequency);
            file:close();
        else
            if (frequency ~= "" and frequency ~= nil) then
                print("Malformed or invalid input. Will use default.");
            end
        end
    end
else
    print("WARNING: This computer cannot connect to the Internet, severely limiting Cobalt's functionality.");
end

print("Setup complete. Thank you for using Cobalt!");