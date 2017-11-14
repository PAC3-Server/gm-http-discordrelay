local luaerror_to_channel = {}
local discordrelay = discordrelay
luaerror_to_channel.errors = {}

local function post(channel, msg)
    discordrelay.CreateMessage(channel, msg, function(h, b, c)
        if discordrelay.util.badcode[c] then
            discordrelay.log(2, "DiscordRelayErrorMsg failed", discordrelay.util.badcode[c])
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
            ["mention"] = "208633661787078657", -- caps
            ["important"] = true
        },
        ["notagain"] = {
            ["url"] = "https://github.com/PAC3-Server/notagain/tree/master/",
            ["mention"] = nil -- notagain or server role maybe?
        },
        ["easychat"] = {
            ["url"] = "https://github.com/PAC3-Server/EasyChat/tree/master/",
            ["mention"] = "205976012050268160" -- earu
        },
        ["gm-http-discordrelay"] = {
            ["url"] = "https://github.com/PAC3-Server/gm-http-discordrelay/tree/master/",
            ["mention"] = "94829082360942592", -- techbot
        },
        ["includes"] = { -- garry stuff
            ["url"] = "https://github.com/Facepunch/garrysmod/tree/master/garrysmod/",
            ["mention"] = nil
        }
    }

    local function DoError(infotbl, locals, trace, client)
        local id = util.CRC(trace)
        if luaerror_to_channel.errors[id] then return end
        local info = infotbl[1]
        local info2 = infotbl[2]
        local src = info["short_src"]
        local addon = src:match("lua/(.-)/")
        addon = string.lower(addon)

        if not github[addon] then -- try info2
            local prev_addon = info2["short_src"]:match("lua/(.-)/")
            addon = prev_addon and string.lower(prev_addon)
        end

        trace = trace:gsub(">", "\\>")
        trace = trace:gsub("<", "\\<")

        local markup = string.gsub(trace, "(lua/.-):(%d+):?", function(l, n)
            local n = n or ""
            local addon = l:match("lua/(.-)/")
            return addon and (github[addon] and "[" .. l .. ":" .. n .. ":](" .. github[addon].url .. l .. "#L" .. n .. ")")
                or l .. n
        end)

        post(github[addon] and (github[addon].important and development) or channel,
            {
                ["content"] = github[addon] and (github[addon].mention and ("<@" .. github[addon].mention .. ">\n")) or "",
                ["embed"] = {
                    ["title"] = (addon or "lua") .. " error" .. (client and (" from: " .. client:Nick()) or "" ),
                    ["description"] = "```lua\n" .. locals .. "```\n" .. markup,
                    ["type"] = "rich",
                    ["color"] = 0xb30000
                }
            })

        luaerror_to_channel.errors[id] = {addon or "generic", {info = {infotbl[1], infotbl[2]}, locals = locals, trace = trace}}
    end

    hook.Add("LuaError", "DiscordRelayErrorMsg", function(infotbl, locals, trace)
        DoError(infotbl, locals, trace, false)
    end)

    hook.Add("ClientLuaError", "DiscordRelayClientErrorMsg", function(client, infotbl, locals, trace)
        DoError(infotbl, locals, trace, client)
    end)
end

function luaerror_to_channel.Remove()
    hook.Remove("LuaError", "DiscordRelayErrorMsg")
    hook.Remove("ClientLuaError", "DiscordRelayClientErrorMsg")

    if discordrelay.modules.luaerror_to_channel then
        discordrelay.modules.luaerror_to_channel = nil
    end
end

return luaerror_to_channel