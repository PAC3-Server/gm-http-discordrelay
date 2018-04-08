local luaerror_to_channel = {}
local discordrelay = discordrelay
luaerror_to_channel.errors = {}

local function post(channel, msg)
	discordrelay.CreateMessage(channel, msg, function(h, b, c)
		if discordrelay.util.badcode[c] then
			discordrelay.log(2, "DiscordRelayErrorMsg failed", discordrelay.util.badcode[c], b)
			return
		end
	end)
end

function luaerror_to_channel.Init()
	local channel = "337186861111836684"
	local development = "374455098614743041"

	local github = {
		["pac3"] = {
			["url"] = "https://github.com/CapsAdmin/pac3/tree/master/",
			["icon"] = "https://avatars3.githubusercontent.com/u/204157?v=4",
			--["mention"] = "208633661787078657", -- caps
			["important"] = true
		},
		["notagain"] = {
			["url"] = "https://github.com/PAC3-Server/notagain/tree/master/",
			["icon"] = "https://avatars1.githubusercontent.com/u/25587531?v=4",
			["mention"] = {
				--jrpg = {"208633661787078657", --[["205976012050268160"]]}, -- caps and earu
				goluwa = "208633661787078657", -- caps

			} -- notagain or server role maybe?
		},
		["easychat"] = {
			["url"] = "https://github.com/PAC3-Server/EasyChat/tree/master/",
			["icon"] = "https://avatars2.githubusercontent.com/u/20880060?v=4",
			["mention"] = "205976012050268160" -- earu
		},
		["discordrelay"] = {
			["url"] = "https://github.com/PAC3-Server/gm-http-discordrelay/tree/master/",
			["icon"] = "https://avatars0.githubusercontent.com/u/3000604?v=4",
			["mention"] = "94829082360942592", -- techbot
		},
		["lambda"] = {
			["url"] = "https://github.com/ZehMatt/Lambda/tree/master/",
			["icon"] = "https://avatars3.githubusercontent.com/u/5415177?s=460&v=4",
		},
		["includes"] = { -- garry stuff
			["url"] = "https://github.com/Facepunch/garrysmod/tree/master/garrysmod/",
			["icon"] = "https://avatars0.githubusercontent.com/u/3371040?v=4",
			["mention"] = nil
		},
	}
	github["vgui"] = github["includes"]
	github["weapons"] = github["includes"]
	github["entities"] = github["includes"]
	github["derma"] = github["includes"]
	github["menu"] = github["includes"]
	github["matproxy"] = github["includes"]
	github["vgui"] = github["includes"]
	github["weapons"] = github["includes"]
	github["gamemodes/base"] = github["includes"]
	github["gamemodes/sandbox"] = github["includes"]
	github["gamemodes/lambda"] = github["lambda"]

	hook.Add("LuaError", "DiscordRelayErrorMsg", function(msg, traceback, stack, client)
		client = IsValid(client) and client

		if client then
			if client.discordrelay_luaerror_halt_time and client.discordrelay_luaerror_halt_time < SysTime() then return end

			if client.discordrelay_luaerror_next_check and client.discordrelay_luaerror_next_check < SysTime() then
				if client.discordrelay_luaerror_count > 10 then
					client.discordrelay_luaerror_halt_time = SysTime() + 30
					client.discordrelay_luaerror_count = 0
					discordrelay.log(2, client, "is erroring 10 different errors in less than a second")
					discordrelay.log(2, client, "not accepting errors from this player for 30 seconds")
					return
				end
			end
		end

		-- sorta kinda makes it not unique every frame
		local hash = msg .. traceback:gsub(" = .-\n", "")

		if luaerror_to_channel.errors[hash] then return end
		luaerror_to_channel.errors[hash] = true

		if client then
			client.discordrelay_luaerror_count = (client.discordrelay_luaerror_count or 0) + 1
			client.discordrelay_luaerror_next_check = SysTime() + 1
		end

		local max_level = #stack
		local min_level = 5

		local mentions = ""
		local urls = ""
		do
			local mentioned = {}

			local function url_from_info(info, i, line)
				local url_name = info.source:match(".+/(lua/.-%.lua)") or info.source:match("@(lua/.-%.lua)") or info.source:match("@(gamemodes/.-%.lua)")
				local addon_info
				if url_name then
					url_name = url_name .. ":" .. line
					local addon_name = info.source:match("lua/(.-)/") or info.source:match("@(gamemodes/.-)/")
					if addon_name and github[addon_name:lower()] then
						addon_info = github[addon_name:lower()]

						local url = info.source:gsub(addon_name:StartWith("gamemodes") and "@.-(gamemodes/.+)" or "@.-(lua/.+)", function(path)
							return addon_info.url .. path
						end)
						url = url .. "#L" .. line
						url = "[" .. url_name .. "](" .. url .. ")"

						if (i - min_level - 1) == -1 then
							urls = urls .. "__**>>** **" .. url .. "** **<<**__"
						else
							urls = urls .. "`" .. (i - min_level - 1) .. ":` " .. url
						end

						if type(addon_info.mention) == "string" then
							if not mentioned[addon_info.mention] then
								mentions = mentions .. " <@" .. addon_info.mention .. ">"
								mentioned[addon_info.mention] = true
							end
						elseif type(addon_info.mention) == "table" then
							for find, ids in pairs(addon_info.mention) do
								if url:find(find, nil, true) then
									for _, id in ipairs(type(ids) == "string" and {ids} or ids) do
										if not mentioned[id] then
											mentions = mentions .. " <@" .. id .. ">"
											mentioned[id] = true
										end
									end
								end
							end
						end
					end
				end

				if not addon_info then
					local source = info.source
					if source == "=[C]" then
						source = source .. " " .. info.name
					else
						source = source .. ":" .. line
					end

					if (i - min_level - 1) == -1 then
						urls = urls .. "__**>>** `" .. source .. "` **<<**__"
					else
						urls = urls .. "`" .. (i - min_level - 1) .. ":` " .. source
					end
				end

				urls = urls .. "\n"
			end

			-- first frame we need to use linedefined instead of currentline
			url_from_info(stack[max_level], max_level + 1, stack[max_level].linedefined)

			for i = max_level, min_level, -1 do
				url_from_info(stack[i], i, stack[i].currentline)
			end
		end

		local addon_info
		local addon_name = (stack[min_level].source:match("lua/(.-)/") or stack[min_level].source) or "???"
		if addon_name and github[addon_name:lower()] then
			addon_info = github[addon_name:lower()]
		end

		msg = msg:gsub("^.-%.lua.-: ", "") -- remove the location as it's not needed

		local author = "lua error from " .. (client and client:Nick() or "SERVER")

		traceback = "```lua\n" .. traceback:sub(-1900) .. "```\n"

		avatar = client and discordrelay.util.GetAvatar(client:SteamID())

		post(addon_info and (addon_info.important and development) or channel,
			{
				--content = author .. msg .. "\n```lua\n" .. traceback:sub(-1900) .. "```\n" .. urls,
				["content"] = "**" .. msg .. "**" .. mentions .. "\n" .. traceback,
				embed = {
					["description"] = urls:sub(-1900),
					["type"] = "rich",
					["color"] = 0x700000,
					["author"] = {
						["name"] = author,
						["url"] = client and ("http://steamcommunity.com/profiles/" .. tostring(util.SteamIDTo64(client:SteamID()))) or (addon_info and addon_info.url) or "",
						["icon_url"] = avatar and tostring(avatar) or (addon_info and addon_info.icon or "https://robohash.org/" .. (addon_name == "=[C]" and (stack[max_level].name or "internal") or addon_name) .. ".png")
					},
					["footer"] = {
						["text"] = tostring(os.date())
					}
				}
			}
		)
	end)
end

function luaerror_to_channel.Remove()
	hook.Remove("LuaError", "DiscordRelayErrorMsg")

	if discordrelay.modules.luaerror_to_channel then
		discordrelay.modules.luaerror_to_channel = nil
	end
end

return luaerror_to_channel