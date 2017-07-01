local ingame_msg = {}
local discordrelay = discordrelay

function ingame_msg.Init()

    hook.Add("PlayerSay", "DiscordRelayChat", function(ply, text, teamChat)
        if aowl then
            if string.match(text,"^[%.|%/|%!].+") then
                return
            end
        end
        if discordrelay and discordrelay.enabled then
            --Parse mentions and replace it into the message
            if string.match(text, "@%a+") then
                for n in string.gmatch( text, "@(%a+)") do
                    local member = discordrelay.members[string.lower(n)]
                    if member then
                        text = string.Replace(text, "@"..n, "<@"..member.user.id..">")
                    end
                end
            end

            text = string.Replace(text, "@everyone", "everyone")
            text = string.Replace(text, "@here", "here")

            discordrelay.util.GetAvatar(ply:SteamID(), function(ret)
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["username"] = ply:Nick(),
                    ["content"] = text,
                    ["avatar_url"] = ret
                })
            end)
        end
    end)
end

function ingame_msg.Remove()
    hook.Remove("PlayerSay", "DiscordRelayChat")
    if discordrelay.modules.ingame_msg then
        discordrelay.modules.ingame_msg = nil
    end
end

return ingame_msg
