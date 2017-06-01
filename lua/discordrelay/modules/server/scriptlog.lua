local discordrelay = discordrelay
local easylua = requirex('easylua')
local luadev = requirex('luadev')
local logChannel = "280436597248229376"
if not easylua or not luadev then discordrelay.log("easylua or luadev not found, scriptlogging disabled.") return false end

local blacklist = {"suicided", "Bad SetLocalOrigin"}
local logBuffer = ""

timer.Create("DiscordRelayAddLog", 1.5, 0, function()
    if logBuffer ~= "" then
        discordrelay.CreateMessage(logChannel, "```"..logBuffer.."```")
        logBuffer = ""
    end
end)

hook.Add("EngineSpew", "DiscordRelaySpew", function(spewType, msg, group, level)
    for k,v in pairs(blacklist) do
        if string.match(msg, v) then
            return
        end
    end

    logBuffer = logBuffer..msg
end )