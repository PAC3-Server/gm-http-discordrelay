local discordrelay = discordrelay

gameevent.Listen( "player_connect" )
hook.Add("player_connect", "DiscordRelayPlayerConnect", function(data)
    if discordrelay and discordrelay.enabled then
        discordrelay.GetAvatar(data.networkid, function(ret)
        local commid = util.SteamIDTo64(data.networkid)
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
                ["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
                ["embeds"] = {
                    [1] = {
                        ["title"] = "",
                        ["description"] = "is joining the Server.",
                        ["author"] = {
                            ["name"] = data.name,
                            ["icon_url"] = ret,
                            ["url"] = "http://steamcommunity.com/profiles/" .. commid
                        },
                        ["type"] = "rich",
                        ["color"] = 0x00b300
                    }
                }
            })
        end)
    end
end)

gameevent.Listen( "player_disconnect" )
hook.Add("player_disconnect", "DiscordRelayPlayerDisconnect", function(data)
    if discordrelay and discordrelay.enabled then
        local commid = util.SteamIDTo64(data.networkid)
        local reason = (string.StartWith(data.reason ,"Map") or string.StartWith(data.reason ,data.name) or string.StartWith(data.reason ,"Client" )) and ":interrobang: "..data.reason or data.reason

        discordrelay.GetAvatar(data.networkid, function(ret)
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
                ["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
                ["embeds"] = {
                    [1] = {
                        ["title"] = "",
                        ["description"] = "left the Server.",
                        ["author"] = {
                            ["name"] = data.name,
                            ["icon_url"] = ret,
                            ["url"] = "http://steamcommunity.com/profiles/" .. commid
                        },
                        ["type"] = "rich",
                        ["color"] = 0xb30000,
                        ["fields"] = {
                            [1] = {
                                ["name"] = "Reason:",
                                ["value"] = reason,
                                ["inline"] = false
                            }
                        }
                    }
                }
            })
        end)
    end
end)
