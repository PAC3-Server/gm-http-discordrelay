local discord_msg = {}
local discordrelay = discordrelay

function discord_msg.Handle(input,previous,future)
    if input.author.discriminator ~= "0000" then
        discordrelay.log(1,input,input.author)
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
        if input.embeds then
            for i=1,#input.embeds do
                ret = ret .. "\n" .. input.embeds[i].title .. "\n" .. input.embeds[i].description
            end
        end
        local send = hook.Run("DiscordRelayMessage", input)
        if send ~= false then
            net.Start( "DiscordMessage" )
                net.WriteString(string.sub(input.author.username,1,25))
                net.WriteString(string.sub(ret,1,600))
            net.Broadcast()
        end
    elseif input.webhook_id then
        local name = input.author.username
        local test = discordrelay.test
        local istest = string.match(name,"Test ⮞ ") and true or false -- well it works
        local isnormal = string.match(name,"Main ⮞ ") and true or false
        name = string.gsub(name,"([A-Za-z]+%s⮞%s","")
        if (test and isnormal and not istest) or (not test and not isnormal and istest) then -- kill me
            local send = hook.Run("DiscordRelayXMessage", input)
            if send ~= false then
                net.Start( "DiscordXMessage" )
                    net.WriteString(string.sub(name,1,25))
                    net.WriteString(string.sub(input.content,1,600))
                    net.WriteBool(test)
                net.Broadcast()
            end
        end
    end
end

function discord_msg.Remove()
    if discordrelay.modules.discord_msg then
        discordrelay.modules.discord_msg = nil
    end
end

discordrelay.modules.discord_msg = discord_msg