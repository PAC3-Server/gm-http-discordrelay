local status = {}
local discordrelay = discordrelay

function status.Handle(input, previous, future)
    if input.author.bot ~= true and discordrelay.util.startsWith(input.content, "status") then
        local embeds = {}
        local amount = player.GetCount()
        local cache = discordrelay.AvatarCache -- todo check if not nil
        for i,ply in pairs(player.GetAll()) do
            local commid = util.SteamIDTo64(ply:SteamID()) -- move to player meta?
            local godmode = ply:GetInfo("cl_godmode") or 1
            local emojis = {
                ["🚗"] = ply:InVehicle(),
                ["⌨"] = ply:IsTyping(),
                ["🔌"] = ply:IsTimingOut(),
                ["❄"] = ply:IsFrozen(),
                ["🤖"] = ply:IsBot(),
                ["🛡"] = ply:IsAdmin(),
                ["👍"] = ply:IsPlayingTaunt(),
                ["⛩"] = ply:HasGodMode() or (tonumber(godmode) and tonumber(godmode) > 0) or godmode ~= "0",
                ["💡"] = ply:FlashlightIsOn(),
                ["💀"] = not ply:Alive(),
                ["🕴"] = ply:GetMoveType() == MOVETYPE_NOCLIP,
                ["💤"] = ply:IsAFK(),
                --[""] = ply:IsMuted(),
                --[""] = ply:IsSpeaking(),
            }
            local emojistr = ""
            for emoji, yes in pairs(emojis) do
                if yes then
                    emojistr = " " .. emojistr .. emoji
                end
            end
            embeds[i] = {
                ["author"] = {
                    ["name"] = string.gsub(ply:Nick(),"<.->","") .. (emojistr and ( " [" .. emojistr .. " ]") or ""),
                    ["icon_url"] = cache[commid] or "https://i.imgur.com/ovW4MBM.png",
                    ["url"] = "http://steamcommunity.com/profiles/" .. commid,

                },
                ["fields"] = {
                    [1] = {
                        ["name"] = ":timer:",
                        ["value"] = string.NiceTime(ply:TimeConnected()),
                        ["inline"] = true

                    },
                    [2] = {
                        ["name"] = ":heartpulse:",
                        ["value"] = ply:Health(),
                        ["inline"] = true
                    },
                    [3] = {
                        ["name"] = ":clock:",
                        ["value"] = string.NiceTime(ply:GetTotalTime()) or "???",
                        ["inline"] = true
                    }
                },
                ["color"] = ply:IsAFK() and 0xffff00 or (ply:Alive() and 0x00b300 or 0xb30000)
            }
        end
        if amount > 0 then
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = "Server status:",
                ["avatar_url"] = discordrelay.avatar,
                ["content"] = "**Hostname:** " .. GetHostName() ..
                    "\n**Uptime:** " .. string.NiceTime(CurTime()) ..
                    "\n**Map:** `" .. game.GetMap() ..
                    "`\n**Players:** " .. amount .. "/" ..  game.MaxPlayers() ..
                    "\nWant to join? Click this link: steam://connect/threekelv.in",
                ["embeds"] = embeds
        })
        else
            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                ["username"] = discordrelay.username,
                ["avatar_url"] = discordrelay.avatar,
                ["embeds"] = {
                    [1] = {
                        ["title"] = "Server status:",
                        ["description"] = "No Players are currently on the Server...\nWant to join? Click this link: steam://connect/threekelv.in",
                        ["type"] = "rich",
                        ["color"] = 0x5a5a5a
                    }
                }
            })
        end
    end
end

function status.Remove()
    if discordrelay.modules.status then
        discordrelay.modules.status = nil
    end
end

return status
