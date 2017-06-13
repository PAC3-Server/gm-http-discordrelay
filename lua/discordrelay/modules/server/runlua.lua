local runlua = {}
local discordrelay = discordrelay
local easylua = requirex('easylua')
local luadev = requirex('luadev')
local prefixes = discordrelay.prefixes
local webhookid_scriptlog = "285359393124384770"

local webhooktoken_scriptlog = file.Read( "webhook_token_scriptlog.txt", "DATA" )

if not webhooktoken_scriptlog then
    discordrelay.log(2,"scriptlog.lua","webhooktoken_scriptlog.txt", " not found. Script logging will be disabled.")
    return false
end

local function getType(cmds, msg)
    if not cmds or not msg then return end
    for k,v in pairs(prefixes) do
        for k,cmd in pairs(cmds) do
            if string.StartWith(msg, v..cmd.." ") then
                return cmd
            end
        end
    end
    return false
end

hook.Add("LuaDevRunScript", "DiscordRelay", function(script, ply, where, identifier, targets)
    identifier = identifier:match("<(.-)>")

    if targets then
        local str = {}
        for k,v in pairs(targets) do
            table.insert(str, tostring(v))
        end
        where = table.concat(str, ", ")
    end

    discordrelay.GetAvatar(ply:SteamID(), function(ret)
        discordrelay.ExecuteWebhook(webhookid_scriptlog, webhooktoken_scriptlog, {
            ["username"] = discordrelay.username,
            ["avatar_url"] = discordrelay.avatar,
            ["content"] = "```lua\n"..string.sub(script, 0, 1990).."\n```",
            ["embeds"] = {
                [1] = {
                    ["title"] = "",
                    ["description"] = "ran " .. identifier .. " " .. where,
                    ["author"] = {
                        ["name"] = ply:Nick(),
                        ["icon_url"] = ret,
                        ["url"] = "http://steamcommunity.com/profiles/" .. ply:SteamID64()
                    },
                    ["type"] = "rich",
                    ["color"] = 0x00b300
                }
            }
        })
    end)
end)

function runlua.Handle(input)
    if input.author.bot ~= true and startsWith("l", input.content) or startsWith("print", input.content) or startsWith("table", input.content) then
        discordrelay.IsAdmin(input.author.id, function(access)
            if access then
                local cmd = getType({"l", "lc", "ls", "print", "table"}, input.content)
                print(cmd,input.content)
                local code = string.sub(input.content, #cmd + 2, #input.content)
                if code and code ~= "" then
                    local data
                    if cmd == "l" then
                        data = easylua.RunLua(nil, code)
                    elseif cmd == "lc" then
                        data = luadev.RunOnClients(code)
                    elseif cmd == "ls" then
                        data = luadev.RunOnShared(code)
                    elseif cmd == "print" then
                        data = easylua.RunLua(nil, "return "..code)
                    elseif cmd == "table" then
                        data = easylua.RunLua(nil, "return table.ToString("..code..")")
                    else
                        return
                    end

                    if type(data) ~= "table" then
                        local ok, returnvals = data
                        if returnvals then
                            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                                ["embeds"] = {
                                    [1] = {
                                    ["description"] = returnvals,
                                        ["type"] = "rich",
                                        ["color"] = 0x182687
                                    }
                                }
                            })
                        else
                            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                                ["embeds"] = {
                                    [1] = {
                                    ["description"] = ":ok_hand:",
                                        ["type"] = "rich",
                                        ["color"] = 0x182687
                                    }
                                }
                            })
                        end
                        return
                    end

                    if not data.error then
                        local res = unpack(data.args)
                        if res and cmd ~= "lc" then
                            res = tostring(res)
                        else
                            res = ":ok_hand:"
                        end
                        discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                            ["embeds"] = {
                                [1] = {
                                ["description"] = res,
                                    ["type"] = "rich",
                                    ["color"] = 0x182687
                                }
                            }
                        })
                    else
                        discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                            ["embeds"] = {
                                [1] = {
                                ["description"] = ":interrobang: **Error: **"..data.error,
                                    ["type"] = "rich",
                                    ["color"] = 0xb30000
                                }
                            }
                        })
                    end
                else
                    discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                        ["embeds"] = {
                            [1] = {
                                ["description"] = ":interrobang: **Cannot run nothing!**",
                                ["type"] = "rich",
                                ["color"] = 0xb30000
                            }
                        }
                    })
                end
            else
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["embeds"] = {
                        [1] = {
                            ["description"] = ":no_entry: **Access denied!**",
                            ["type"] = "rich",
                            ["color"] = 0xb30000
                        }
                    }
                })
            end
        end)
    end
end

return runlua