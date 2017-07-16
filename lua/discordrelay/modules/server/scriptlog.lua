local scriptlog = {}
local discordrelay = discordrelay

function scriptlog.Init()
    local easylua = requirex('easylua')
    local luadev = requirex('luadev')
    local logChannel = "280436597248229376"
    if not easylua or not luadev then discordrelay.log(2,"easylua or luadev not found, scriptlogging disabled.") return false end

    local blacklist = {"suicided", "Bad SetLocalOrigin","Changing collision rules"}
    local logBuffer = ""
    local abort = 0

    timer.Create("DiscordRelayAddLog", 1.5, 0, function()
        if abort >= 5 then discordrelay.log(3,"DiscordRelayAddLog failed DESTROYING") timer.Destroy("DiscordRelayAddLog") return end -- prevent spam
        if logBuffer ~= "" then
            timer.Simple(5, function()
                discordrelay.CreateMessage(logChannel, "```"..logBuffer.."```",function(h,b,c)
                    if discordrelay.util.badcode[c] then
                        abort = abort + 1
                        logBuffer = "" -- clear buffer to get rid of potentally massive logs
                        discordrelay.log(2,"DiscordRelayAddLog failed",discordrelay.util.badcode[c],"retrying",abort)
                        return
                    else
                        abort = 0
                    end
                    end)
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
end

function scriptlog.Remove()
    hook.Remove("EngineSpew", "DiscordRelaySpew")
    timer.Destroy("DiscordRelayAddLog")
    if discordrelay.modules.scriptlog then
        discordrelay.modules.scriptlog = nil
    end
end

return scriptlog