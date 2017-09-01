local join_leave_msg = {}
local discordrelay = discordrelay

function join_leave_msg.Init()
    gameevent.Listen( "player_connect" )
    hook.Add("player_connect", "DiscordRelayPlayerConnect", function(data)
        if discordrelay and discordrelay.enabled then
            discordrelay.util.GetAvatar(data.networkid, function(ret)
            local commid = util.SteamIDTo64(data.networkid)

            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = discordrelay.username,
                ["avatar_url"] = discordrelay.avatar,
                ["embeds"] = {
                    [1] = {
                        ["title"] = "",
                        ["description"] = "**is joining the Server.**\n:inbox_tray:",
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

            discordrelay.util.GetAvatar(data.networkid, function(ret)
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["username"] = discordrelay.username,
                    ["avatar_url"] = discordrelay.avatar,
                    ["embeds"] = {
                        [1] = {
                            ["title"] = "",
                            ["description"] = "**left the Server.**\n:outbox_tray:",
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
end

function join_leave_msg.Remove()
    hook.Remove("player_disconnect", "DiscordRelayPlayerDisconnect")
    hook.Remove("player_connect", "DiscordRelayPlayerConnect")
    if discordrelay.modules.join_leave_msg then
        discordrelay.modules.join_leave_msg = nil
    end
end

return join_leave_msg