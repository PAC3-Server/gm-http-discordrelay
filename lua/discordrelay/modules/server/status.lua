local status = {}
local tag = "DiscordrelayUpdateTopic"
local discordrelay = discordrelay
local abort = 0
local startsWith = discordrelay.util.startsWith

function status.DiscordrelayUpdateTopic()
    if abort >= 3 then -- prevent spam
        discordrelay.log(3,tag,"failed DESTROYING")
        hook.Remove("PlayerConnect",tag)
        hook.Remove("PlayerDisconnected",tag)
        return
    end
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
            discordrelay.log(2,tag,"failed",discordrelay.util.badcode[c],"retrying",abort)
            return
        else
            abort = 0 -- all good now
        end
    end,
    function(err)
        discordrelay.log(3,tag,err)
    end)
end

function status.Init()
    status.DiscordrelayUpdateTopic()
    gameevent.Listen("player_connect")
    hook.Add("player_connect",tag,status.DiscordrelayUpdateTopic)
    gameevent.Listen( "player_disconnect")
    hook.Add("player_disconnect",tag,status.DiscordrelayUpdateTopic)
end

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

function status.Remove()
    hook.Remove("player_connect",tag)
    hook.Remove("player_disconnect",tag)
    if discordrelay.modules.status then
        discordrelay.modules.status = nil
    end
end

return status