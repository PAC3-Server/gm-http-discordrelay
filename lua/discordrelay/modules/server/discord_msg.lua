local discord_msg = {}
local discordrelay = discordrelay

util.AddNetworkString("DiscordMessage")

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
        net.Start( "DiscordMessage" )
            net.WriteString(string.sub(input.author.username,1,14))
            net.WriteString(string.sub(ret,1,400))
        net.Broadcast()

        hook.Run("DiscordRelayMessage", input)
    end
end

function discord_msg.Remove()
end

return discord_msg