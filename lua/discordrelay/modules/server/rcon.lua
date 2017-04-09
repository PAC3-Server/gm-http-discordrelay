local rcon = {}
local discordrelay = discordrelay

function rcon.Handle(input)
    if startsWith("rcon", input.content) then
        discordrelay.IsAdmin(input.author.id, function(access)
            if access then
                game.ConsoleCommand(string.sub(input.content, 6, #input.content).."\n")
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["embeds"] = {
                        [1] = {
                        ["description"] = ":ok_hand:",
                            ["type"] = "rich",
                            ["color"] = 0x182687
                        }
                    }
                })

            else
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["embeds"] = {
                        [1] = {
                            ["description"] = ":no_entry: **Access denied!**",
                            ["type"] = "rich",
                            ["color"] = 0xb30000
                        }
                    }
                })
            end
        end)
        net.Start( "DiscordMessage" )
            net.WriteString(string.sub(input.author.username,1,14))
            net.WriteString(string.sub(input.content,1,400))
        net.Broadcast()
    end
end
return rcon