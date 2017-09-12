local scriptlog = {}
local discordrelay = discordrelay

function scriptlog.Init()
    local logChannel = "337186861111836684"

    local blacklist = {"suicided", "Bad SetLocalOrigin","Changing collision rules"}
    local logBuffer = ""
    local abort = 0

    timer.Create("DiscordRelayAddLog", 5, 0, function()
        if abort >= 5 then discordrelay.log(3,"DiscordRelayAddLog failed DESTROYING") timer.Destroy("DiscordRelayAddLog") return end -- prevent spam
        if logBuffer ~= "" then
            discordrelay.CreateMessage(logChannel, "```"..string.sub(logBuffer,1,2000).."```",function(h,b,c)
                if discordrelay.util.badcode[c] then
                    abort = abort + 1
                    logBuffer = "" -- clear buffer to get rid of potentally massive logs
                    discordrelay.log(2,"DiscordRelayAddLog failed",discordrelay.util.badcode[c],"retrying",abort)
                    return
                else
                    abort = 0
                end
            end)
            logBuffer = ""
        end
    end)

    hook.Add("EngineSpew", "DiscordRelaySpew", function(spewType, msg, group, level)
        msg = string.gsub(msg,'"','\"')
        msg = string.gsub(msg,"%d+%.%d+%.%d+%.%d+","XXX.XXX.XXX.XXX")
        for i=1,#blacklist do
            if string.match(msg, blacklist[i]) then
                return
            end
        end

        logBuffer = logBuffer..msg
    end)
end

function scriptlog.Remove()
    hook.Remove("EngineSpew", "DiscordRelaySpew")
    timer.Destroy("DiscordRelayAddLog")
    if discordrelay.modules.scriptlog then
        discordrelay.modules.scriptlog = nil
    end
end

return scriptlog