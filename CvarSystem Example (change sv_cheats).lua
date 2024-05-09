-- SYR1337
local ICvarSystem = (function()
    local bLoadedBinrary, szLibraryBinrary = pcall(file.Read, "Cvar System.lua")
    if not bLoadedBinrary then
        return nil
    end

    local bLoad, fnGetCvarSystem = pcall(loadstring, szLibraryBinrary)
    if not bLoad then
        return nil
    end

    return fnGetCvarSystem()
end)()

assert(ffi, "example error: ffi is not open, please open ffi")
assert(ICvarSystem, [[example error: ICvarSystem is not loaded, please copy source and rename "Cvar System.lua" and put inside aimware lua folder]])

local pConVar = ICvarSystem["sv_cheats"]
print("sv_cheats: ", pConVar:bool())
print("set sv_cheats to true")
pConVar:bool(true)
print("sv_cheats: ", pConVar:bool())
