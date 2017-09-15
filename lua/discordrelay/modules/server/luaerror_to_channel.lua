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
    local who, last

    local github = {
        ["pac3"] = {
            ["url"] = "https://github.com/CapsAdmin/pac3/tree/master/lua/",
            ["mention"] = "208633661787078657", -- caps
            ["important"] = true
        },
        ["notagain"] = {
            ["url"] = "https://github.com/PAC3-Server/notagain/tree/master/lua/",
            ["mention"] = "" -- notagain or server role maybe?
        },
        ["easychat"] = {
            ["url"] = "https://github.com/PAC3-Server/EasyChat/tree/master/lua/",
            ["mention"] = "205976012050268160" -- earu
        }
    }

    hook.Add("EngineSpew", "DiscordRelayErrorMsg", function(spewType, msg, group, level)
        if not msg or (msg:sub(1, 1) ~= "[" and msg:sub(1, 2) ~= "\n[") then return end

        if msg:find("] Lua Error:", 1, true) then -- client error
            local err = msg
            local pl, userid = false, err:match(".+|(%d*)|.-$")

            if userid then
                userid = tonumber(userid)
                pl = Player(userid)
            end

            err = err and err:gsub("^\n*", "") -- trim newlines from beginning
            err = err and err:gsub("[\n ]+$", "") -- and end

            who = (IsValid(pl) and tostring(pl) or err)
            last = RealTime()
        end

        if msg:sub(1, 9) == "\n[ERROR] " then -- server error
            local err = msg:sub(10, -1)
            local id = util.CRC(err)
            if luaerror_to_channel.errors[id] then return end
            local now = RealTime()

            if last then
                now = now - last
            end

            local addon = err:match("addons/(.-)/") or "lua"
            local laddon = string.lower(addon)
            local path, line = msg:match("%[ERROR%] addons/.-/lua/(.+):(%d+):.+")

            post(github[laddon] and (github[laddon].important and programming) or channel,
            {
                ["content"] = github[laddon] and (github[laddon].mention and ("<@" .. github[laddon].mention .. ">\n")) or "",
                ["embed"] = {
                    ["title"] = addon .. " error" .. ((now and now < 2) and (" from: " .. who) or ""),
                    ["description"] = "```" .. err .. "```" .. (github[laddon] and ( "\n[Github Link](" .. github[laddon].url .. path .. (line and "#L".. line or "") .. ")") or ""),
                    ["type"] = "rich",
                    ["color"] = 0xb30000
                }
            })
            luaerror_to_channel.errors[id] = {laddon,err}
        end
    end)
end

function luaerror_to_channel.Remove()
    hook.Remove("EngineSpew", "DiscordRelayErrorMsg")

    if discordrelay.modules.luaerror_to_channel then
        discordrelay.modules.luaerror_to_channel = nil
    end
end

return luaerror_to_channel