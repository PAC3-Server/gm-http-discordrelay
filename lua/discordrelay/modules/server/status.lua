local status = {}
local discordrelay = discordrelay

function status.Handle(input)
    if input.author.bot ~= true and string.StartWith(input.content, "<@"..discordrelay.user.id.."> status") or startsWith("status", input.content) then
        local embeds = {}
        local players = player.GetAll()
        local cache = discordrelay.AvatarCache -- todo check if not nil
        for i=1,#players do
            local ply = players[i]
            local commid = util.SteamIDTo64(ply:SteamID()) -- move to player meta?
            embeds[i] = {
                ["author"] = {
                    ["name"] = ply:Nick(),["icon_url"] = cache[commid],
                    ["url"] = "http://steamcommunity.com/profiles/" .. commid
                },
                ["color"] = (ply:IsAFK() ~= nil and ply:IsAFK()) and 0xffff00 or 0x00b300
            }
        end
        if #players > 0 then
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = "Server status:",
                ["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
                ["content"] = "**Hostname:** "..GetHostName().."\n**Uptime:** "..string.FormattedTime(SysTime()/3600,"%02i:%02i:%02i").."\n**Map:** `"..game.GetMap().."`\n**Players:** "..#players.."/"..game.MaxPlayers(),
                ["embeds"] = embeds
        })
        else
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
                ["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
                ["embeds"] = {
                    [1] = {
                        ["title"] = "Server status:",
                        ["description"] = "No Players are currently on the Server...",
                        ["type"] = "rich",
                        ["color"] = 0x5a5a5a
                    }
                }
            })
        end
    end
end
return status