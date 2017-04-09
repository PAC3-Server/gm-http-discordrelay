discordrelay = discordrelay or {}
discordrelay.log = function(...) Msg("[DiscordRelay] ") print(...) end
discordrelay.config = {}

-- token for reading messages and core functionality
local token = file.Read( "discordbot_token.txt", "DATA" )

if not token then
    discordrelay.log("discordbot_token.txt", "not found.")
end

if not token then return end

discordrelay.config.webhookenabled = true

-- webhooktoken for posting messages
local webhooktoken = file.Read( "webhook_token.txt", "DATA" )

if not webhooktoken then
    discordrelay.log("webhook_token.txt", " not found. Discordrelay unable to post messages on Discord.")
    discordrelay.config.webhookenabled = false
end

-- main config
discordrelay.token = token
discordrelay.guild = "260866188962168832"
discordrelay.admin_roles = {"260870255486697472", "260932947140411412"}
discordrelay.relayChannel = "273575417401573377"
discordrelay.logChannel = "280436597248229376"
discordrelay.scriptLogChannel = "285346539638095872"

discordrelay.webhookid = "274957435091812352"
discordrelay.webhooktoken = webhooktoken

discordrelay.webhookid_scriptlog = "285359393124384770"
discordrelay.webhooktoken_scriptlog = webhooktoken_scriptlog

discordrelay.endpoints = discordrelay.endpoints or {}
discordrelay.endpoints.base = "https://discordapp.com/api/v6"
discordrelay.endpoints.users = discordrelay.endpoints.base.."/users"
discordrelay.endpoints.guilds = discordrelay.endpoints.base.."/guilds"
discordrelay.endpoints.channels = discordrelay.endpoints.base.."/channels"
discordrelay.endpoints.webhook = "https://canary.discordapp.com/api/webhooks"

discordrelay.enabled = true

discordrelay.user = {}
discordrelay.user.username = "GMod-Relay"
discordrelay.user.id = "276379732726251521"

discordrelay.prefixes = {".", "!"}

discordrelay.AvatarCache = discordrelay.AvatarCache or {}

discordrelay.modules = {}
discordrelay.extensions = {}

-- modules
local function LoadModule(path)
    if not file.Exists(path,"LUA") then
        discordrelay.log("Modules Error:",path,"not found")
    end
    local func = CompileFile(path)
    if type(func) ~= "string" then
        return func
    end
    return nil
end

if file.Exists("discordrelay/modules/server","LUA") then
    for _,file in pairs (file.Find("discordrelay/modules/server/*.lua", "LUA")) do
        local name = string.StripExtension(file)
        local func = LoadModule("discordrelay/modules/server/"..file)
        local ok, mod = pcall(func)
        if not ok then continue end -- even if a single modules fail don't exit loop
        if type(mod) == "string" then
            discordrelay.log("Module Error:",file,"contained errors and will not be loaded!")
            continue
        elseif mod == nil then
            discordrelay.log("Extension:",file,"loaded.")
            discordrelay.extensions[name] = func
            continue
        end
        
        discordrelay.modules[name] = mod
        discordrelay.log("Discord Modules:",name,"loaded.")
    end
end
if file.Exists("discordrelay/modules/client","LUA") then
    for _,file in pairs (file.Find("discordrelay/modules/client/*.lua", "LUA")) do
        AddCSLuaFile("discordrelay/modules/client/"..file)
    end
end

include("discordrelay/helpers.lua") -- todo: remove???????

function discordrelay.HTTPRequest(ctx, callback, err)
    local HTTPRequest = {}
    HTTPRequest.method = ctx.method
    HTTPRequest.url = ctx.url
    HTTPRequest.headers = {
        ["Authorization"]= "Bot "..discordrelay.token,
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "GModRelay (https://datamats.com/, 1.0.0)"
    }

    HTTPRequest.type = "application/json"

    if ctx.body then
        HTTPRequest.body = ctx.body
    elseif ctx.parameters then
        HTTPRequest.parameters = ctx.parameters
    end

    HTTPRequest.success = function(code, body, headers)
    if not callback then return end
        callback(headers, body)
    end

    HTTPRequest.failed = function(reason)
    if not err then return end
        err(reason)
    end

    HTTP(HTTPRequest)
end

function discordrelay.WebhookRequest(ctx, callback, err)
    local HTTPRequest = {}
    HTTPRequest.method = ctx.method
    HTTPRequest.url = ctx.url
    HTTPRequest.headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = string.len(ctx.body) or "0"
    }

    HTTPRequest.type = "application/json"

    if ctx.body then
        HTTPRequest.body = ctx.body
    elseif ctx.parameters then
        HTTPRequest.parameters = ctx.parameters
    end

    HTTPRequest.success = function(code, body, headers)
    if not callback then return end
        callback(headers, body)
    end

    HTTPRequest.failed = function(reason)
    if not err then return end
        err(reason)
    end

    HTTP(HTTPRequest)
end

function discordrelay.GetAvatar(steamid, callback)
    local commid = util.SteamIDTo64(steamid)
    if discordrelay.AvatarCache[commid] then
        callback(discordrelay.AvatarCache[commid])
    else
        http.Fetch("http://steamcommunity.com/profiles/" .. commid .. "?xml=1", function(content, size)
            local ret = content:match("<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>") or "http://i.imgur.com/ovW4MBM.png"
            discordrelay.AvatarCache[commid] = ret
            callback(ret)
        end)
    end
end

function discordrelay.IsAdmin(userid, cb)
    discordrelay.HTTPRequest({
        ["method"] = "get",
        ["url"] = discordrelay.endpoints.guilds.."/"..discordrelay.guild.."/members/"..userid
    }, function(headers, body)
        local tbl = util.JSONToTable(body)
        if tbl.roles then
            for k,role in pairs(discordrelay.admin_roles) do
                for k,v in pairs(tbl.roles) do
                    if role == v then
                        return cb(true)
                    end
                end
            end
        end
        cb(false)
    end)
end

function discordrelay.CreateMessage(channelid, msg, cb) -- still keeping this if we want to post anything in the future, feel free to remove though
    local res
    if type(msg) == "string" then
        res = util.TableToJSON({["content"] = msg})
    elseif type(msg) == "table" then
        res = util.TableToJSON(msg)
    else
        return discordrelay.log("Relay: attempting to send a invalid message")
    end
    discordrelay.HTTPRequest({
        ["method"] = "post",
        ["url"] = discordrelay.endpoints.channels.."/"..channelid.."/messages",
        ["body"] = res
    }, function(headers, body)
        if not cb then return end
        local tbl = util.JSONToTable(body)
        cb(tbl)
    end)
end

function discordrelay.ExecuteWebhook(whid, whtoken, msg, cb)
    if discordrelay.config.webhookenabled == false then return end
    local res
    if type(msg) == "string" then
        res = util.TableToJSON({["content"] = msg})
    elseif type(msg) == "table" then
        res = util.TableToJSON(msg)
    else
        return discordrelay.log("Relay: attempting to send a invalid message")
    end
    discordrelay.WebhookRequest({
        ["method"] = "POST",
        ["url"] = discordrelay.endpoints.webhook.."/"..whid.."/"..whtoken,
        ["body"] = res

    }, function(headers, body)
    if not cb then return end
        local tbl = util.JSONToTable(body)
        cb(tbl)
    end,function(err) discordrelay.log(err) end)
end

local after = 0
local lastid
--It was either this or websockets. But this shouldn't be that bad of a solution
timer.Create("DiscordRelayFetchMessages", 1.5, 0, function()
    local url
    if after ~= 0 then
        url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages?after="..after
    else
        url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages"
    end

    discordrelay.HTTPRequest({["method"] = "get", ["url"] = url}, function(headers, body)
        local json = util.JSONToTable(body)
        
        if json and json[1] and after ~= 0 and lastid ~= json[1].id then
            for k,v in ipairs(json) do
                if not (v and v.author) and discordrelay.user.id == v.author.id or type(v) == "number" then continue end
                if v.webhook_id and v.webhook_id == discordrelay.webhookid then continue end

                for name,module in pairs(discordrelay.modules) do
                    local ok,why = pcall(module.Handle,v)
                    if not ok then 
                        discordrelay.log("Module Error:",name,why)
                        -- todo: make point to github
                        discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                            ["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
                            ["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
                            ["embeds"] = {
                                [1] = {
                                    ["title"] = "MODULE ERROR: "..name,
                                    ["description"] = "```"..why.."```",
                                    ["type"] = "rich",
                                    ["color"] = 0xb30000
                                }
                            }
                        })
                    end
                end
            end
        end

        if json and json[1] then
            after = json[1].id
            lastid = json[1].id
        end
    end)
end)

hook.Add("ShutDown", "DiscordRelayShutDown", function()
    if discordrelay and discordrelay.enabled then
        discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
            ["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
            ["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
            ["embeds"] = {
                [1] = {
                    ["title"] = "",
                    ["description"] = "**Server has shutdown.**",
                    ["type"] = "rich",
                    ["color"] = 0xb30000
                }
            }
        })
    end
end)