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
            ["mention"] = "208633661787078657", -- caps
            ["important"] = true
        },
        ["notagain"] = {
            ["url"] = "https://github.com/PAC3-Server/notagain/tree/master/",
            ["icon"] = "https://avatars1.githubusercontent.com/u/25587531?v=4",
            ["mention"] = nil -- notagain or server role maybe?
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
        ["includes"] = { -- garry stuff
            ["url"] = "https://github.com/Facepunch/garrysmod/tree/master/garrysmod/",
            ["icon"] = "https://avatars0.githubusercontent.com/u/3371040?v=4",
            ["mention"] = nil
        }
    }
    github["vgui"] = github["includes"]
    github["weapons"] = github["includes"]
    github["entities"] = github["includes"]
    github["derma"] = github["includes"]
    github["menu"] = github["includes"]
    github["vgui"] = github["includes"]
    github["weapons"] = github["includes"]

    hook.Add("LuaError", "DiscordRelayErrorMsg", function(msg, traceback, stack, client)
        if luaerror_to_channel.errors[msg] then return end

		local addon_info
		local addon_name

		for i, info in ipairs(stack) do
			addon_name = info.source:match("lua/(.-)/")
			if addon_name and github[addon_name:lower()] then
				addon_info = github[addon_name:lower()]
				break
			end
		end

		if not addon_name then
			addon_name = stack[1].source or "???"
		end

		if addon_info then
			traceback = traceback:gsub("(lua/.-):(%d+):?", function(path, line)
				return "[" .. path .. ":" .. line .. ":](" .. addon_info.url .. path .. "#L" .. line .. ")"
			end)
		end

        client = IsValid(client) and client
        avatar = client and discordrelay.util.GetAvatar(client:SteamID())

        post(addon_info and (addon_info.important and development) or channel,
            {
                ["content"] = addon_info and (addon_info.mention and ("<@" .. addon_info.mention .. ">\n")) or "",
                ["embed"] = {
                    ["title"] = msg,
                    ["description"] = string.sub(traceback, 1, 2030 - #traceback),
                    ["type"] = "rich",
                    ["color"] = 0xb30000,
                    ["author"] = {
                        ["name"] = addon_name .. " lua error" .. (client and (" from: " .. client:Nick()) or ""),
                        ["url"] = client and ("http://steamcommunity.com/profiles/" .. tostring(util.SteamIDTo64(client:SteamID()))) or (addon_info and addon_info.url) or "",
                        ["icon_url"] = avatar and tostring(avatar) or (addon_info and addon_info.icon or "https://identicons.github.com/" .. addon_name .. ".png")
                    },
                    ["footer"] = {
                        ["text"] = tostring(os.date())
                    }
                }
            })

        luaerror_to_channel.errors[msg] = {addon or "generic", stack = stack, msg = msg}
    end)
end

function luaerror_to_channel.Remove()
    hook.Remove("LuaError", "DiscordRelayErrorMsg")

    if discordrelay.modules.luaerror_to_channel then
        discordrelay.modules.luaerror_to_channel = nil
    end
end

return luaerror_to_channel