local discord_msg = {}
local discordrelay = discordrelay

function discord_msg.Handle(input)
    if input.author.bot ~= true then
        local ret = input.content
        if input.mentions then
            for k,mention in pairs(input.mentions) do
                ret = string.gsub(input.content, "<@!?"..mention.id..">", "@"..mention.username)
            end
        end
        if input.attachments then
            for _,attachments in pairs(input.attachments) do
                ret = ret .. "\n" .. attachments.url
            end
        end
        local send = hook.Run("DiscordRelayMessage", input)
        send = send or true
        if send then
            net.Start( "DiscordMessage" )
                net.WriteString(string.sub(input.author.username,1,14))
                net.WriteString(string.sub(ret,1,400))
            net.Broadcast()
        end
    end
end

function discord_msg.Remove()
    if discordrelay.modules.discord_msg then
        discordrelay.modules.discord_msg = nil
    end
end

return discord_msg