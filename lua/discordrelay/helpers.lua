--todo remove????
local discordrelay = discordrelay
local prefixes = discordrelay.prefixes

function startsWith(name, msg, param)
    if not name or not msg then return end
    for k,v in pairs(prefixes) do
        if string.StartWith(msg, v..name) then
            return true
        end
    end
    return false
end

