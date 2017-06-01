if SERVER then
    include("discordrelay/sv_discordrelay.lua")
    AddCSLuaFile("discordrelay/cl_discordrelay.lua")
end

if CLIENT then
    include("discordrelay/cl_discordrelay.lua")
end