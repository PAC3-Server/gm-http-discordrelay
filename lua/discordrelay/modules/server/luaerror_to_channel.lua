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
    local programming = "278624981192146944"

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
        }
    }
    local function DoError(infotbl, locals, trace, client)
        local info = infotbl[1]
        local info2 = infotbl[2]
        local src = info["short_src"]
        local addon = src:match("addons/(.-)/lua/")
        local path = src:match("/(lua/.+)")
        local line = info["currentline"]
        local start = info["linedefined"]
        local last = info["lastlinedefined"]
        if not addon then
            local prev_src = info2["short_src"]:match("addons/(.-)/lua/")
            local prev_path = info2["short_src"]:match("/(lua/.+)")
            line = info2["currentline"]
            start = info2["linedefined"]
            last = info2["lastlinedefined"]
            addon = prev_src and string.lower(prev_src)
            path = prev_path
        end

        local id = util.CRC(trace)
        if luaerror_to_channel.errors[id] then return end

        post(github[addon] and (github[addon].important and programming) or channel,
            {
                ["content"] = github[addon] and (github[addon].mention and ("<@" .. github[addon].mention .. ">\n")) or "",
                ["embed"] = {
                    ["title"] = (addon or "lua") .. " error" .. (client and (" from: " .. client:Nick()) or "" ),
                    ["description"] = "```lua\n" .. locals .. "```\n```" .. trace .. "```" .. (github[addon] and
                        ("\n[Error at Function](" .. github[addon].url .. path .. "#L".. start .. "-L" .. last .. ")\n[Error at line](" .. github[addon].url .. path .. "#L".. line .. ")")
                        or ""),
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