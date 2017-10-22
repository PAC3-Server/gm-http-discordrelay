local aowl_commands = {}
local discordrelay = discordrelay
function aowl_commands.Init()

    hook.Add("AowlCommand", "DiscordrelayAowlMsg", function(command, alias, ply, arg_line, args)
        local tracked = { "restart", "reboot", "rank", "ban", "unban", "kick" }

        if not tracked[alias] then return end

        if ply then
            discordrelay.util.GetAvatar(ply:SteamID(), function(ret)
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["username"] = discordrelay.username,
                    ["avatar_url"] = discordrelay.avatar,
                    ["embeds"] = {
                        [1] = {
                            ["title"] = "",
                            ["description"] = "**aowl:** " .. url,
                            ["author"] = {
                                ["name"] = (string.gsub(ply:Nick(),"<.->","")),
                                ["icon_url"] = ret,
                                ["url"] = "http://steamcommunity.com/profiles/" .. commid
                            },
                            ["type"] = "rich",
                            ["fields"] = {
                                [1] = {
                                    ["name"] = "Command:",
                                    ["value"] = alias .. tostring(unpack(args)),
                                    ["inline"] = false
                                }
                            },
                            ["color"] = 0xffff00
                        }
                    }
                })
            end)
        else
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = discordrelay.username,
                ["avatar_url"] = discordrelay.avatar,
                ["embeds"] = {
                    [1] = {
                        ["title"] = "",
                        ["description"] = "**aowl:** " .. url,
                        ["author"] = {
                            ["name"] = "???"
                        },
                        ["type"] = "rich",
                        ["fields"] = {
                            [1] = {
                                ["name"] = "Command:",
                                ["value"] = alias .. tostring(unpack(args)),
                                ["inline"] = false
                            }
                        },
                        ["color"] = 0xffff00
                    }
                }
            })
        end
    end)

    hook.Add("AowlTargetCommand", "DiscordrelayBanMsg", function(ply, what, target, extra)
        if what ~= "ban" then return end
        if discordrelay and discordrelay.enabled then
            local steamid = ply:SteamID()
            local targetid = type(target) == "string" and target or target:SteamID()
            local commid = util.SteamIDTo64(steamid)
            local url = "http://steamcommunity.com/profiles/" .. util.SteamIDTo64(targetid)
            local time = extra["time"]
            local reason = extra["reason"]

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
                                },
                                [2] = {
                                    ["name"] = "Time:",
                                    ["value"] = string.NiceTime(time),
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

    hook.Add("AowlTargetCommand", "DiscordrelayUnbanMsg", function(ply, what, target, extra)
        if what ~= "unban" then return end
            if discordrelay and discordrelay.enabled then
            local steamid = ply:SteamID()
            local commid = util.SteamIDTo64(steamid)
            local targetid = type(target) == "string" and target or target:SteamID()
            local url = "http://steamcommunity.com/profiles/" .. util.SteamIDTo64(targetid)
            local reason = extra["reason"]

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

function aowl_commands.Remove()
    hook.Remove("AowlTargetCommand", "DiscordrelayBanMsg")
    hook.Remove("AowlTargetCommand", "DiscordrelayUnbanMsg")
    hook.Remove("AowlCommand", "DiscordrelayAowlMsg")
    if discordrelay.modules.aowl_commands then
        discordrelay.modules.aowl_commands = nil
    end
end

return aowl_commands
