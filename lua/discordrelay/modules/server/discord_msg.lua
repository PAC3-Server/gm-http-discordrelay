local discord_msg = {}
local discordrelay = discordrelay

function discord_msg.Handle(input,previous,future)
    if input.author.discriminator ~= "0000" then -- ignore webhooks but allow other bots
        local ret = input.content
        if input.mentions then
            for k,mention in pairs(input.mentions) do
                ret = string.gsub(input.content, "<@!?" .. mention.id .. ">", "@" .. mention.username)
            end
        end
        if input.attachments then
            for _,attachments in pairs(input.attachments) do
                ret = ret .. "\n" .. attachments.url
            end
        end
        if input.embeds then
            for i = 1, #input.embeds do
                ret = ret .. "\n" .. (input.embeds[i].title and input.embeds[i].title or "") .. "\n" .. input.embeds[i].description
            end
        end
        local send = hook.Run("DiscordRelayMessage", input)
        if send ~= false then
            net.Start( "DiscordMessage" )
                net.WriteString(string.sub(input.author.username,1,25))
                net.WriteString(string.sub(ret,1,600))
            net.Broadcast()
        end
    elseif input.webhook_id then -- handle webhook
        return
    end
end

function discord_msg.Remove()
    if discordrelay.modules.discord_msg then
        discordrelay.modules.discord_msg = nil
    end
end

return discord_msg