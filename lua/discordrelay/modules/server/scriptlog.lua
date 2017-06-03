local discordrelay = discordrelay
local easylua = requirex('easylua')
local luadev = requirex('luadev')
local logChannel = "280436597248229376"
if not easylua or not luadev then discordrelay.log("easylua or luadev not found, scriptlogging disabled.") return false end

local blacklist = {"suicided", "Bad SetLocalOrigin"}
local logBuffer = ""
local abort = 0

timer.Create("DiscordRelayAddLog", 1.5, 0, function()
    if abort >= 5 then discordrelay.log("DiscordRelayAddLog failed DESTROYING") timer.Destroy("DiscordRelayAddLog") return end -- prevent spam
    if logBuffer ~= "" then
        discordrelay.CreateMessage(logChannel, "```"..logBuffer.."```",function(h,b,c)
            if discordrelay.util.badcode[c] then 
                abort = abort + 1 
                discordrelay.log("DiscordRelayAddLog failed",discordrelay.util.badcode[c],"retrying",abort) return end 
            end)
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
end)