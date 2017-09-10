local aowl_ban = {}
local discordrelay = discordrelay

function aowl_ban.Init()
    hook.Add("AowlTargetCommand", "DiscordrelayBanMsg", function(ply, what, target, reason)
        if what ~= "ban" then return end
        if discordrelay and discordrelay.enabled then
            local steamid = ply:SteamID()
            local targetid = type(target) == "string" and target or target:SteamID()
            local commid = util.SteamIDTo64(steamid)
            local url = "http://steamcommunity.com/profiles/" .. util.SteamIDTo64(targetid)

            discordrelay.util.GetAvatar(steamid, function(ret)
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["username"] = discordrelay.username,
                    ["avatar_url"] = discordrelay.avatar,
                    ["embeds"] = {
                        [1] = {
                            ["title"] = "",
                            ["description"] = "**BANNED:** " .. url,
                            ["author"] = {
                                ["name"] = (string.gsub(ply:Nick(),"<.->","")),
                                ["icon_url"] = ret,
                                ["url"] = "http://steamcommunity.com/profiles/" .. commid
                            },
                            ["type"] = "rich",
                            ["fields"] = {
                                [1] = {
                                    ["name"] = "Reason:",
                                    ["value"] = reason,
                                    ["inline"] = false
                                }
                            },
                            ["color"] = 0xb30000
                        }
                    }
                })
            end)
        end
    end)

    hook.Add("AowlTargetCommand", "DiscordrelayUnbanMsg", function(ply, what, target, reason)
        if what ~= "unban" then return end
            if discordrelay and discordrelay.enabled then
            local steamid = ply:SteamID()
            local commid = util.SteamIDTo64(steamid)
            local targetid = type(target) == "string" and target or target:SteamID()
            local url = "http://steamcommunity.com/profiles/" .. util.SteamIDTo64(targetid)

            discordrelay.util.GetAvatar(steamid, function(ret)
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["username"] = discordrelay.username,
                    ["avatar_url"] = discordrelay.avatar,
                    ["embeds"] = {
                        [1] = {
                            ["title"] = "",
                            ["description"] = "**UNBANNED:** " .. url,
                            ["author"] = {
                                ["name"] = (string.gsub(ply:Nick(),"<.->","")),
                                ["icon_url"] = ret,
                                ["url"] = "http://steamcommunity.com/profiles/" .. commid
                            },
                            ["type"] = "rich",
                            ["fields"] = {
                                [1] = {
                                    ["name"] = "Reason:",
                                    ["value"] = reason,
                                    ["inline"] = false
                                }
                            },
                            ["color"] = 0x00b300
                        }
                    }
                })
            end)
        end
    end)
end

function aowl_ban.Remove()
    hook.Remove("AowlTargetCommand", "DiscordrelayBanMsg")
    hook.Remove("AowlTargetCommand", "DiscordrelayUnbanMsg")
    if discordrelay.modules.aowl_ban then
        discordrelay.modules.aowl_ban = nil
    end
end

return aowl_ban
