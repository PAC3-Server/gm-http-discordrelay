local status = {}
local discordrelay = discordrelay
local abort = 0

function status.ChannelTopicPatch()
    timer.Create("DiscordRelayChannelTopic", 10, 0, function()
        if abort >= 3 then discordrelay.log("DiscordRelayChannelTopic failed DESTROYING") timer.Destroy("DiscordRelayChannelTopic") return end -- prevent spam
        local res = util.TableToJSON({
            ["name"] = "server-chat",
            ["position"] = 7,
            ["topic"] = GetHostName().." - **Uptime:** "..string.FormattedTime(SysTime()/3600,"%02i:%02i:%02i").." - **Players:** "..player.GetCount().."/"..game.MaxPlayers().."\nsteam://connect/threekelv.in".."\n\nType !status in chat for more detailed info."
        })
        -- patch returned not allowed so what gives
        discordrelay.HTTPRequest({
            ["method"] = "put",
            ["url"] = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel,
            ["body"] = res
            },
            function(h,b,c)
                if discordrelay.util.badcode[c] then 
                    abort = abort + 1 
                    discordrelay.log("DiscordRelayAddLog failed",discordrelay.util.badcode[c],"retrying",abort) 
                return end
            end,
            function(err) 
                discordrelay.log("DiscordRelayChannelTopic",err) 
             end)
    end)
end
status.ChannelTopicPatch()
hook.Add("PlayerConnect", "DiscordrelayUpdateTopic", status.ChannelTopicPatch)
hook.Add("PlayerDisconnected", "DiscordrelayUpdateTopic", status.ChannelTopicPatch)

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
                ["avatar_url"] = discordrelay.avatar,
                ["content"] = "**Hostname:** "..GetHostName().."\n**Uptime:** "..string.FormattedTime(SysTime()/3600,"%02i:%02i:%02i").."\n**Map:** `"..game.GetMap().."`\n**Players:** "..#players.."/"..game.MaxPlayers(),
                ["embeds"] = embeds
        })
        else
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = discordrelay.username,
                ["avatar_url"] = discordrelay.avatar,
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