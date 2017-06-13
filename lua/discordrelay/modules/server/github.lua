local github = {}
local discordrelay = discordrelay

function github.Handle(input)
    if input.webhook_id and string.lower(input.author.username) == "github" and input.embeds and input.embeds[1] then
        local embed = input.embeds[1]
        if string.match(embed.title, "new commit") then
            local message = "GitHub: "..embed.title
            for k,v in pairs(string.Split(embed.description, "\n")) do
                local hash, url, commit = string.match(v, "%[`(.*)`%]%((.*)%) (.*)")
                message = message.."\n	"..hash.." "..commit
            end
            net.Start( "DiscordMessage" )
                net.WriteString("")
                net.WriteString(message)
            net.Broadcast()
        else
            net.Start( "DiscordMessage" )
                net.WriteString("")
                net.WriteString("GitHub: "..embed.title)
            net.Broadcast()
        end
    end
end

function github.Remove()
end

return github