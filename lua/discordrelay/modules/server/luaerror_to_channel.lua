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

    hook.Add("LuaError", "DiscordRelayErrorMsg", function(info, locals, trace)
        local src = info["short_src"]
        local addon = src:match("addons/(.-)/lua/") and string.lower(src:match("addons/(.-)/lua/"))
        local path = src:match("/(lua/.+)")
        local line = info["currentline"]
        local start = info["linedefined"]
        local last = info["lastlinedefined"]

        local id = util.CRC(trace)
        if luaerror_to_channel.errors[id] then return end

        post(github[addon] and (github[addon].important and programming) or channel,
            {
                ["content"] = github[addon] and (github[addon].mention and ("<@" .. github[addon].mention .. ">\n")) or "",
                ["embed"] = {
                    ["title"] = (addon or "Lua") .. " error",
                    ["description"] = "```" .. trace .. "```" .. (github[addon] and
                        ("\n[Function](" .. github[addon].url .. path .. "#L".. line .. ")\n[At](" .. github[addon].url .. path .. "#L".. start .. "-L" .. last .. ")")
                        or ""),
                    ["type"] = "rich",
                    ["color"] = 0xb30000
                }
            })
        luaerror_to_channel.errors[id] = {addon or "generic", {info = info, locals = locals, trace = trace}}
    end)
end

function luaerror_to_channel.Remove()
    hook.Remove("LuaError", "DiscordRelayErrorMsg")

    if discordrelay.modules.luaerror_to_channel then
        discordrelay.modules.luaerror_to_channel = nil
    end
end

return luaerror_to_channel