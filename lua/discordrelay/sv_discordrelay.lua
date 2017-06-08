discordrelay = discordrelay or {}
discordrelay.log = function(...) Msg("[DiscordRelay] ") print(...) end -- todo: add support for strings and tables (maybe more???)
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
discordrelay.username = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server"
discordrelay.avatar = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png"
discordrelay.token = token
discordrelay.guild = "260866188962168832"
discordrelay.admin_roles = {"260870255486697472", "260932947140411412"}
discordrelay.relayChannel = "273575417401573377"

discordrelay.webhookid = "274957435091812352"
discordrelay.webhooktoken = webhooktoken

discordrelay.endpoints = discordrelay.endpoints or {}
discordrelay.endpoints.base = "https://discordapp.com/api"
discordrelay.endpoints.users = discordrelay.endpoints.base.."/users"
discordrelay.endpoints.guilds = discordrelay.endpoints.base.."/guilds"
discordrelay.endpoints.channels = discordrelay.endpoints.base.."/channels"
discordrelay.endpoints.webhook = discordrelay.endpoints.base.."/webhooks"

discordrelay.enabled = true

discordrelay.user = {}
discordrelay.user.username = "GMod-Relay"
discordrelay.user.id = "276379732726251521"

discordrelay.members = discordrelay.members or {}

discordrelay.prefixes = {".", "!"}

discordrelay.AvatarCache = discordrelay.AvatarCache or {}

discordrelay.modules = {}
discordrelay.extensions = {}

AccessorFunc(discordrelay, "enabled", "Enabled", FORCE_BOOL)

discordrelay.util = {}
discordrelay.util.badcode = {
    [400] = "BAD REQUEST",
    [401] = "UNAUTHORIZED",
    [403] = "FORBIDDEN",
    [404] = "NOT FOUND",
    [405] =  "METHOD NOT ALLOWED",
    [429] = "TOO MANY REQUESTS",
    [502] = "GATEWAY UNAVAILABLE"
    }

function discordrelay.HTTPRequest(ctx, callback, err)
    local HTTPRequest = {}
    HTTPRequest.method = ctx.method
    HTTPRequest.url = ctx.url
    HTTPRequest.headers = {
        ["Authorization"]= "Bot "..discordrelay.token,
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "DiscordBot (https://github.com/PAC3-Server/gm-http-discordrelay, 1.0.0)"
    }

    HTTPRequest.type = "application/json"

    if ctx.body then
        HTTPRequest.body = ctx.body
    elseif ctx.parameters then
        HTTPRequest.parameters = ctx.parameters
    end

    HTTPRequest.success = function(code, body, headers)
    if discordrelay.util.badcode[code] then discordrelay.log("HTTPRequest",ctx.url,discordrelay.util.badcode[code]) end
    if not callback then return end
    callback(headers, body, code)
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
    }, function(headers, body, code)
        if not cb then return end
        local tbl = util.JSONToTable(body)
        cb(headers,tbl,code)
    end,function(err) discordrelay.log("CreateMessage failed:",channelid,msg,err) end)
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
    end,function(err) discordrelay.log("WebhookFailed:",whid,msg,err) end)
end

function discordrelay.FetchMembers()
    local url = discordrelay.endpoints.guilds.."/"..(guildid or discordrelay.guild).."/members?limit=1000"
    discordrelay.HTTPRequest({["method"] = "get", ["url"] = url}, function(headers, body, code)
        for k,v in pairs(util.JSONToTable(body)) do
            discordrelay.members[string.lower(v.user.username)] = v
        end
    end)
end

timer.Create("DiscordFetchMembers", 60*20, 0, discordrelay.FetchMembers)

hook.Add("PostGamemodeLoaded", "FetchDiscordMembersStartup", discordrelay.FetchMembers)

local after = 0
local abort = 0
local lastid


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

include("discordrelay/helpers.lua") -- todo: remove???????

if file.Exists("discordrelay/modules/server","LUA") then
    for _,file in pairs (file.Find("discordrelay/modules/server/*.lua", "LUA")) do
        local name = string.StripExtension(file)
        local func = LoadModule("discordrelay/modules/server/"..file)
        local ok, mod = pcall(func)
        if not ok then continue end -- even if a single modules fail don't exit loop
        if type(mod) == "string" then
            discordrelay.log("Module Error:",file,"contained errors and will not be loaded!")
            continue
        elseif mod == false then
            discordrelay.log("Extension:",file,"NOT loaded. (returned false)")
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

--It was either this or websockets. But this shouldn't be that bad of a solution
timer.Create("DiscordRelayFetchMessages", 1.5, 0, function()
if abort >= 5 then discordrelay.log("FetchMessages failed DESTROYING") timer.Destroy("DiscordRelayFetchMessages") return end -- prevent spam
local url
    if after ~= 0 then
        url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages?after="..after
    else
        url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages"
    end
    discordrelay.HTTPRequest({["method"] = "get", ["url"] = url}, function(headers, body, code)
        if discordrelay.util.badcode[code] then abort = abort + 1 discordrelay.log("FetchMessages failed",discordrelay.util.badcode[code],"retrying",abort) return end
        local json = util.JSONToTable(body)
        if json and json[1] and after ~= 0 and lastid ~= json[1].id then
            abort = 0 -- json is valid so we got something
            for k,v in ipairs(json) do
                if not (v and v.author) and discordrelay.user.id == v.author.id or type(v) == "number" then continue end
                if v.webhook_id and v.webhook_id == discordrelay.webhookid then continue end

                for name,module in pairs(discordrelay.modules) do
                    local ok,why = pcall(module.Handle,v)
                    if not ok then 
                        discordrelay.log("Module Error:",name,why)
                        discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
                            ["username"] = discordrelay.username,
                            ["avatar_url"] = discordrelay.avatar,
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
            ["username"] = discordrelay.username,
            ["avatar_url"] = discordrelay.avatar,
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