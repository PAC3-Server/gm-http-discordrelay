local aowl_ban = {}
local discordrelay = discordrelay

function aowl_ban.Init()
    hook.Add("AowlTargetCommand", "DiscordrelayBanMsg", function(ply, what, target, reason)
        if not what == "ban" then return end
            if discordrelay and discordrelay.enabled then
            local commid = util.SteamIDTo64(ply:SteamID())

            discordrelay.util.GetAvatar(commid, function(ret)
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["username"] = discordrelay.username,
                    ["avatar_url"] = discordrelay.avatar,
                    ["embeds"] = {
                        [1] = {
                            ["title"] = "",
                            ["description"] = "**BANNED:** " .. (string.gsub(target:Nick(),"<.->","")),
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
end

function aowl_ban.Remove()
    hook.Remove("AowlTargetCommand", "DiscordrelayBanMsg")
    if discordrelay.modules.aowl_ban then
        discordrelay.modules.aowl_ban = nil
    end
end

return aowl_ban