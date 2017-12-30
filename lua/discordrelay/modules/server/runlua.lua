local runlua = {}
local discordrelay = discordrelay
local prefixes = discordrelay.prefixes
local easylua = requirex("easylua")
local luadev = requirex("luadev")

if not easylua or not luadev then discordrelay.log(2, "easylua or luadev not found, runlua disabled.") return false end

local function getType(msg, cmds)
    if not cmds or not msg or type(cmds) ~= "table" then return end
    local found
    for i = 1, #cmds do
        found = string.match(msg, "[" .. table.concat(prefixes, "|") .. "](" .. cmds[i] .. ")")
        if found then
            found = found
            break
        end
    end
    return found
end

function runlua.Init()
    local webhookid_scriptlog = "285359393124384770"

    local webhooktoken_scriptlog = file.Read( "webhook_token_scriptlog.txt", "DATA" )

    if not webhooktoken_scriptlog then
        discordrelay.log(2, "scriptlog.lua", "webhooktoken_scriptlog.txt", " not found. Script logging will be disabled.")
        return false
    end

    hook.Add("LuaDevRunScript", "DiscordRelay", function(script, ply, where, identifier, targets)
        identifier = identifier:match("<(.-)>")
        if not identifier then
            identifier = "unknown"
        end

        if targets then
            local str = {}
            for k, v in pairs(targets) do
                table.insert(str, tostring(v))
            end
            where = table.concat(str, ", ")
        end

        discordrelay.util.GetAvatar(ply:SteamID(), function(ret)
            discordrelay.ExecuteWebhook(webhookid_scriptlog, webhooktoken_scriptlog, {
                ["username"] = discordrelay.username,
                ["avatar_url"] = discordrelay.avatar,
                ["content"] = "```lua\n" .. string.sub(script, 0, 1990) .. "\n```",
                ["embeds"] = {
                    [1] = {
                        ["title"] = "",
                        ["description"] = "ran " .. identifier .. " " .. where,
                        ["author"] = {
                            ["name"] = string.gsub(ply:Nick(), "<.->", ""),
                            ["icon_url"] = ret,
                            ["url"] = "http://steamcommunity.com/profiles/" .. ply:SteamID64()
                        },
                        ["type"] = "rich",
                        ["color"] = 0x008000
                    }
                }
            })
        end)
    end)
end

function runlua.Handle(input)
    if input.author.bot ~= true and discordrelay.util.startsWith(input.content, {"l", "print", "table"}) then
        discordrelay.util.IsAdmin(input.author.id, function(access)
            if access then
                local cmd = getType(input.content, {"l", "lc", "ls", "lsc", "print", "table"})
                local code = string.sub(input.content, #cmd + 2, #input.content)
                if code and code ~= "" then
                    local data
                    if cmd == "l" then
                        data = easylua.RunLua(nil, code)
                    elseif cmd == "lc" then
                        data = luadev.RunOnClients(code, "discord:lc")
                    elseif cmd == "lsc" then
                        local args = string.Split(code, ", ")
                        if not args[1] or not args[2] then
                            data = {error = "you need to supply both a player and code!"}
                        else
                            args[2] = table.concat(args, ", ", 2)
                            local ent = easylua.FindEntity(string.Replace(args[1], " ", ""))
                            if IsValid(ent) and ent:IsPlayer() then
                                data = luadev.RunOnClient(args[2], ent, "discord:lsc")
                            else
                                data = {error = "that is not a valid player!"}
                            end
                        end
                    elseif cmd == "ls" then
                        data = luadev.RunOnShared(code, "discord:ls")
                    elseif cmd == "print" then
                        data = easylua.RunLua(nil, "return " .. code)
                    elseif cmd == "table" then
                        data = easylua.RunLua(nil, "return table.ToString(" .. code .. ")")
                    else
                        return
                    end

                    if type(data) ~= "table" then
                        local ok, returnvals = data
                        if returnvals then
                            discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                                ["username"] = discordrelay.username,
                                ["avatar_url"] = discordrelay.avatar,
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
                                ["username"] = discordrelay.username,
                                ["avatar_url"] = discordrelay.avatar,
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
                            ["username"] = discordrelay.username,
                            ["avatar_url"] = discordrelay.avatar,
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
                            ["username"] = discordrelay.username,
                            ["avatar_url"] = discordrelay.avatar,
                            ["embeds"] = {
                                [1] = {
                                ["description"] = ":interrobang: **Error: **" .. data.error,
                                    ["type"] = "rich",
                                    ["color"] = 0x700000
                                }
                            }
                        })
                    end
                else
                    discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                        ["username"] = discordrelay.username,
                        ["avatar_url"] = discordrelay.avatar,
                        ["embeds"] = {
                            [1] = {
                                ["description"] = ":interrobang: **Cannot run nothing!**",
                                ["type"] = "rich",
                                ["color"] = 0x700000
                            }
                        }
                    })
                end
            else
                discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                    ["username"] = discordrelay.username,
                    ["avatar_url"] = discordrelay.avatar,
                    ["embeds"] = {
                        [1] = {
                            ["description"] = ":no_entry: **Access denied!**",
                            ["type"] = "rich",
                            ["color"] = 0x700000
                        }
                    }
                })
            end
        end)
    end
end

function runlua.Remove ()
    hook.Remove("LuaDevRunScript", "DiscordRelay")
    if discordrelay.modules.runlua then
        discordrelay.modules.runlua = nil
    end
end

return runlua