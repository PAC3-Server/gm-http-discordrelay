local discordrelay = discordrelay
local easylua = requirex('easylua')
local luadev = requirex('luadev')

if not easylua or not luadev then discordrelay.log("easylua or luadev not found, scriptlogging disabled.") return end

local webhooktoken_scriptlog = file.Read( "webhook_token_scriptlog.txt", "DATA" )

if not webhooktoken_scriptlog then
    discordrelay.log("webhooktoken_scriptlog.txt", " not found. Script logging will be disabled.")
    return
end

local blacklist = {"suicided", "Bad SetLocalOrigin"}
local logBuffer = ""

timer.Create("DiscordRelayAddLog", 1.5, 0, function()
    if logBuffer ~= "" then
        discordrelay.CreateMessage(discordrelay.logChannel, "```"..logBuffer.."```")
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