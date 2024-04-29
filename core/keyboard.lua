local keyboard = {}

keyboard.keys = {}
keyboard.keysReverse = {}
keyboard.keysDown = {}

function keyboard.isKeyDown(keyCode)
    return keyboard.keysDown[keyCode] == true -- NOT redundant - we want to return "false" if nil
end

function keyboard.isShiftDown()
    return keyboard.isKeyDown(keyboard.keys.lshift) or keyboard.isKeyDown(keyboard.keys.rshift)
end

function keyboard.isCtrlDown()
    return keyboard.isKeyDown(keyboard.keys.lcontrol) or keyboard.isKeyDown(keyboard.keys.rcontrol)
end

-- Only supports alphanumeric keys, and space
function keyboard.getNextKey()
    while true do
        local _, _, _, _, code = thread.wait("key_down")

        if code ~= nil then
            local key = keyboard.keysReverse[code]
            if key ~= nil then
                return keyboard.isShiftDown() and string.upper(key) or key
            end
        end
    end
end

function keyboard.reset()
    keyboard.keysDown = {}
end

-- These functions are only intended to be called by the kernel
function keyboard.handleKeystroke(_, eventName, _, char, code)
    if code ~= nil then
        keyboard.keysDown[code] = eventName == "key_down"
    end
end

function keyboard.getDownListenerThread()
    return thread.create(function()
        while true do keyboard.handleKeystroke(thread.wait("key_down")) end
    end, 1)
end

function keyboard.getUpListenerThread()
    return thread.create(function()
        while true do keyboard.handleKeystroke(thread.wait("key_up")) end
    end, 1)
end

-- Because efficiency (laziness) we only support getting the next alphanumeric keystroke :)
-- TODO maybe fix later
keyboard.keysReverse[0x02] = "1"
keyboard.keysReverse[0x03] = "2"
keyboard.keysReverse[0x04] = "3"
keyboard.keysReverse[0x05] = "4"
keyboard.keysReverse[0x06] = "5"
keyboard.keysReverse[0x07] = "6"
keyboard.keysReverse[0x08] = "7"
keyboard.keysReverse[0x09] = "8"
keyboard.keysReverse[0x0A] = "9"
keyboard.keysReverse[0x0B] = "0"

keyboard.keysReverse[0x1E] = "a"
keyboard.keysReverse[0x30] = "b"
keyboard.keysReverse[0x2E] = "c"
keyboard.keysReverse[0x20] = "d"
keyboard.keysReverse[0x12] = "e"
keyboard.keysReverse[0x21] = "f"
keyboard.keysReverse[0x22] = "g"
keyboard.keysReverse[0x23] = "h"
keyboard.keysReverse[0x17] = "i"
keyboard.keysReverse[0x24] = "j"
keyboard.keysReverse[0x25] = "k"
keyboard.keysReverse[0x26] = "l"
keyboard.keysReverse[0x32] = "m"
keyboard.keysReverse[0x31] = "n"
keyboard.keysReverse[0x18] = "o"
keyboard.keysReverse[0x19] = "p"
keyboard.keysReverse[0x10] = "q"
keyboard.keysReverse[0x13] = "r"
keyboard.keysReverse[0x1F] = "s"
keyboard.keysReverse[0x14] = "t"
keyboard.keysReverse[0x16] = "u"
keyboard.keysReverse[0x2F] = "v"
keyboard.keysReverse[0x11] = "w"
keyboard.keysReverse[0x2D] = "x"
keyboard.keysReverse[0x15] = "y"
keyboard.keysReverse[0x2C] = "z"

keyboard.keysReverse[0x39] = " "
keyboard.keysReverse[0x0E] = "BACK"
keyboard.keysReverse[0x1C] = "ENTER"

-- Declaration of the entire keyboard
-- Taken from OpenComputers, with "extraneous keys" removed
-- We notably do not support the numpad
keyboard.keys["1"]           = 0x02
keyboard.keys["2"]           = 0x03
keyboard.keys["3"]           = 0x04
keyboard.keys["4"]           = 0x05
keyboard.keys["5"]           = 0x06
keyboard.keys["6"]           = 0x07
keyboard.keys["7"]           = 0x08
keyboard.keys["8"]           = 0x09
keyboard.keys["9"]           = 0x0A
keyboard.keys["0"]           = 0x0B
keyboard.keys.a               = 0x1E
keyboard.keys.b               = 0x30
keyboard.keys.c               = 0x2E
keyboard.keys.d               = 0x20
keyboard.keys.e               = 0x12
keyboard.keys.f               = 0x21
keyboard.keys.g               = 0x22
keyboard.keys.h               = 0x23
keyboard.keys.i               = 0x17
keyboard.keys.j               = 0x24
keyboard.keys.k               = 0x25
keyboard.keys.l               = 0x26
keyboard.keys.m               = 0x32
keyboard.keys.n               = 0x31
keyboard.keys.o               = 0x18
keyboard.keys.p               = 0x19
keyboard.keys.q               = 0x10
keyboard.keys.r               = 0x13
keyboard.keys.s               = 0x1F
keyboard.keys.t               = 0x14
keyboard.keys.u               = 0x16
keyboard.keys.v               = 0x2F
keyboard.keys.w               = 0x11
keyboard.keys.x               = 0x2D
keyboard.keys.y               = 0x15
keyboard.keys.z               = 0x2C

keyboard.keys.apostrophe      = 0x28
keyboard.keys.at              = 0x91
keyboard.keys.back            = 0x0E -- backspace
keyboard.keys.backslash       = 0x2B
keyboard.keys.capital         = 0x3A -- capslock
keyboard.keys.colon           = 0x92
keyboard.keys.comma           = 0x33
keyboard.keys.enter           = 0x1C
keyboard.keys.equals          = 0x0D
keyboard.keys.grave           = 0x29 -- accent grave
keyboard.keys.lbracket        = 0x1A
keyboard.keys.lcontrol        = 0x1D
keyboard.keys.lmenu           = 0x38 -- left Alt
keyboard.keys.lshift          = 0x2A
keyboard.keys.minus           = 0x0C
keyboard.keys.numlock         = 0x45
keyboard.keys.pause           = 0xC5
keyboard.keys.period          = 0x34
keyboard.keys.rbracket        = 0x1B
keyboard.keys.rcontrol        = 0x9D
keyboard.keys.rmenu           = 0xB8 -- right Alt
keyboard.keys.rshift          = 0x36
keyboard.keys.scroll          = 0x46 -- Scroll Lock
keyboard.keys.semicolon       = 0x27
keyboard.keys.slash           = 0x35 -- / on main keyboard
keyboard.keys.space           = 0x39
keyboard.keys.stop            = 0x95
keyboard.keys.tab             = 0x0F
keyboard.keys.underline       = 0x93

-- Keypad (and numpad with numlock off)
keyboard.keys.up              = 0xC8
keyboard.keys.down            = 0xD0
keyboard.keys.left            = 0xCB
keyboard.keys.right           = 0xCD
keyboard.keys.home            = 0xC7
keyboard.keys["end"]         = 0xCF
keyboard.keys.pageUp          = 0xC9
keyboard.keys.pageDown        = 0xD1
keyboard.keys.insert          = 0xD2
keyboard.keys.delete          = 0xD3

return keyboard