local luaerror_to_channel = {}
local discordrelay = discordrelay

local function post(channel,msg)
    discordrelay.CreateMessage(channel, msg, function(h,b,c)
        if discordrelay.util.badcode[c] then
            discordrelay.log(2,"DiscordRelayErrorMsg failed",discordrelay.util.badcode[c])
            return
        end
    end)
end

function luaerror_to_channel.Init()
    local channel = "278624981192146944"
    local who, last, spam

    local github = {
        ["pac3"] = "https://github.com/CapsAdmin/pac3/tree/master/lua/",
        ["notagain"] = "https://github.com/PAC3-Server/notagain/tree/master/lua/",
        ["easychat"] = "https://github.com/PAC3-Server/EasyChat/tree/master/lua/"
    }
    hook.Add("EngineSpew", "DiscordRelayErrorMsg", function(spewType, msg, group, level)
        if not msg or (msg:sub(1,1) ~= "[" and msg:sub(1,2) ~= "\n[") then return end
        if msg:find("] Lua Error:",1,true) then -- client error
            local err = msg
            local pl, userid = false, err:match(".+|(%d*)|.-$")

            if userid then
                userid = tonumber(userid)
                pl = Player(userid)
            end

            err = err and err:gsub("^\n*","") -- trim newlines from beginning
            err = err and err:gsub("[\n ]+$","") -- and end

            who = (IsValid(pl) and tostring(pl) or err)
            last = RealTime()
            --return
        end
        if msg:sub(1,9)=="\n[ERROR] " then -- server error
            local err=msg:sub(10,-1)
            local now = RealTime()

            if last then
                now = now - last
            end

            local addon = err:match("addons/(.-)/") or "lua"
            local laddon = string.lower(addon)
            local path, line = msg:match("%[ERROR%] addons/.-/lua/(.+):(%d+):.+")

            post(channel,
            {
                ["embed"] = {
                    ["title"] = addon .. " error" .. ((now and now < 2) and (" from: " .. who) or ""),
                    ["description"] = "```"..err.."```" .. (github[laddon] and "\n" .. (github[laddon] .. path .. (line and "#L".. line or "")) or ""),
                    ["type"] = "rich",
                    ["color"] = 0xb30000
                }
            }
            )
            return
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