local ingame_msg = {}
local discordrelay = discordrelay

local function cleanMassPings(str)
	local ok, n1, n2, n3

	-- Strip bad combinations until they no longer exist or until we have iterated too many times
	for i = 1, 32 do
		str, n1 = str:gsub("%\xE2%\x80%\xAE", "") -- escape RTL chars that discord removes: https://github.com/Eufranio/MagiBridge/blob/6a946b0b32347b107b57fa947410d772104003ff/src/main/java/com/magitechserver/magibridge/discord/DiscordMessageBuilder.java#L32
		str, n2 = str:gsub("@+([Ee][Vv][Ee][Rr][Yy][Oo][Nn][Ee])", "%1")
		str, n3 = str:gsub("@+([Hh][Ee][Rr][Ee])", "%1")

		if n1 + n2 + n3 == 0 then
			ok = true
			break
		end
	end

	if not ok then return (str:gsub("[^a-zA-Z0-9]", "")) end

	return str
end

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
				
			text = cleanMassPings(text)

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
