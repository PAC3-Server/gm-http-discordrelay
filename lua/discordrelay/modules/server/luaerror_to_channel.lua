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

    local function DoError(msg, stack, client)
        local id = util.CRC(msg)
        if luaerror_to_channel.errors[id] then return end

        if not stack or type(stack) ~= "table" then
            discordrelay.log(2, "Invalid Stack??", client)
            return
        end

        local trace = msg
        local addon_name = string.lower(trace:match("lua/(.-)/") or stack[1].what) or "???"
        local extra = trace:match("lua/.-/(.-)/")
        local addon = github[addon_name]

        trace = trace:gsub(">", "\\>")
        trace = trace:gsub("<", "\\<")

        local function getLink(l, n)
            local n = n or ""
            return addon and ("[" .. l .. ":" .. n .. ":](" .. addon.url .. l .. "#L" .. n .. ")")
                or l .. n
        end

        trace = trace:gsub("(lua/.-):(%d+):?", getLink)

        client = IsValid(client) and client
        avatar = client and discordrelay.util.GetAvatar(client:SteamID())

        local locals = string.sub(tostring(stack[2].locals) .. "--\n" .. tostring(stack[3].locals), 1, 2030 - #trace - #stack[1].locals) or "???"
        locals = locals:gsub("`", "\\`")

        post(addon and (addon.important and development) or channel,
            {
                ["content"] = addon and (addon.mention and ("<@" .. addon.mention .. ">\n")) or "",
                ["embed"] = {
                    ["title"] = "",
                    ["description"] = stack[1].locals .. "```lua\n" .. locals .. "```\n" .. trace,
                    ["type"] = "rich",
                    ["color"] = 0xb30000,
                    ["author"] = {
                        ["name"] = ((addon_name .. (extra and ("/" .. extra) or "")) or "lua") .. " error" .. (client and (" from: " .. client:Nick()) or "" ),
                        ["url"] = client and ("http://steamcommunity.com/profiles/" .. tostring(util.SteamIDTo64(client:SteamID()))) or (addon and addon.url) or "",
                        ["icon_url"] = avatar and tostring(avatar) or (addon and addon.icon or "https://identicons.github.com/" .. addon_name .. ".png")
                    },
                    ["footer"] = {
                        ["text"] = tostring(os.date())
                    }
                }
            })

        luaerror_to_channel.errors[id] = {addon or addon_name, stack = stack, msg = msg}
    end

    hook.Add("LuaError", "DiscordRelayErrorMsg", DoError)
    hook.Add("ClientLuaError", "DiscordRelayClientErrorMsg", DoError)
end

function luaerror_to_channel.Remove()
    hook.Remove("LuaError", "DiscordRelayErrorMsg")
    hook.Remove("ClientLuaError", "DiscordRelayClientErrorMsg")

    if discordrelay.modules.luaerror_to_channel then
        discordrelay.modules.luaerror_to_channel = nil
    end
end

return luaerror_to_channel