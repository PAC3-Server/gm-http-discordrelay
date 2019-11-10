local ingame_msg = {}
local discordrelay = discordrelay

function ingame_msg.Init()

	hook.Add("PlayerSay", "DiscordRelayChat", function(ply, text, teamChat)
		if not text or text == "" then return end
		if aowl and aowl.ParseString(text) then
			return
		end

		if discordrelay and discordrelay.enabled then
			--Parse mentions and replace it into the message
			if string.match(text, "@%w+") then
				for n in string.gmatch( text, "@(%w+)") do
					local member = discordrelay.members[string.lower(n)]
					if member then
						text = string.Replace(string.gsub(text,"<.->",""), "@" .. n, "<@" .. member.user.id .. ">")
					end
				end
			end
				
			text = text:gsub("%\x20[%\x2E%\x2D%\x2A%\x2B%\x2C]","")
			text = text:gsub("(@+)everyone", "everyone")
			text = text:gsub("(@+)here", "here")
			

			text = text:gsub("<texture=(.-)>", function(url) return url end)

			discordrelay.util.GetAvatar(ply:SteamID(), function(ret)
				discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
					["username"] = string.sub((not ply:Alive() and "*DEAD* " or "") .. string.gsub(ply:Nick(),"<.->",""),1,32),
					["content"] = text,
					["avatar_url"] = ret
				})
			end)
		end
	end)
end

function ingame_msg.Remove()
	hook.Remove("PlayerSay", "DiscordRelayChat")
	if discordrelay.modules.ingame_msg then
		discordrelay.modules.ingame_msg = nil
	end
end

return ingame_msg
