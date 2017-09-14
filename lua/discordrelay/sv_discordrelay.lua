discordrelay = discordrelay or {}
CreateConVar("sv_testing","0",{FCVAR_NOTIFY,FCVAR_ARCHIVE,FCVAR_REPLICATED},"testing mode") -- hack hack
function discordrelay.log(level,...)  -- most expensive print ever
    local arg = {...}
    local color = {
        [1] = Color(255,255,255),
        [2] = Color(255,222,102),
        [3] = Color(255,0,0)
    }
    local prefix = {
        [1] = {Color(255,182,79),"[DiscordRelay:",Color(255,255,255),"info",Color(255,182,79),"] "},
        [2] = {Color(255,182,79),"[DiscordRelay:",Color(255,222,102),"warning",Color(255,182,79),"] "},
        [3] = {Color(255,182,79),"[DiscordRelay:",Color(255,0,0),"error",Color(255,182,79),"] "}
    }
    local level = math.Clamp(level, 1, #prefix) -- lol
    MsgC(unpack(prefix[level]))
    local out = ""
    local tablespew = {}
    local function insert(inc,val)
        if inc == 1 then
            return val
        else
            return " "..val
        end
    end
    for i,val in ipairs(arg) do
        if type(val) == "table" then
            table.insert(tablespew, val)
        else
            out = out..insert(i,tostring(val))
        end
    end
    MsgC(color[level],out,"\n")
    if tablespew then
        for _,tbl in ipairs(tablespew) do
            for key,value in pairs(tbl) do -- subtables??? who knows
                MsgC(color[level],key," --> ",value,"\n")
            end
        end
    end
end

discordrelay.config = {}

-- token for reading messages and core functionality
local token = file.Read( "discordbot_token.txt", "DATA" )

if not token then
    discordrelay.log(3,"discordbot_token.txt", "not found.")
end

if not token then return end

discordrelay.config.webhookenabled = true

-- webhooktoken for posting messages
local webhooktoken = file.Read( "webhook_token.txt", "DATA" )

if not webhooktoken then
    discordrelay.log(2,"webhook_token.txt", " not found. Discordrelay unable to post messages on Discord.")
    discordrelay.config.webhookenabled = false
end

util.AddNetworkString("DiscordMessage")
util.AddNetworkString("DiscordXMessage")

-- main config
discordrelay.username = discordrelay.test and "Test Server" or "Main Server"
discordrelay.test = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool()
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

AccessorFunc(discordrelay, "enabled", "Enabled", FORCE_BOOL)

discordrelay.util = {}
discordrelay.util.badcode = {
    [400] = "BAD REQUEST",
    [401] = "UNAUTHORIZED",
    [403] = "FORBIDDEN",
    [404] = "NOT FOUND",
    [405] = "METHOD NOT ALLOWED",
    [429] = "TOO MANY REQUESTS",
    [502] = "GATEWAY UNAVAILABLE"
    }

function discordrelay.HTTPRequest(ctx, callback, err)
    local ctx = ctx
    local HTTPRequest = {
        ["method"] = ctx.method,
        ["url"] = ctx.url,
        ["type"] = "application/json",
        ["headers"] = {
            ["Authorization"] = "Bot "..discordrelay.token,
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "DiscordBot (https://github.com/PAC3-Server/gm-http-discordrelay, 1.0.0)"
        },
        ["success"] = function(code, body, headers)
            if discordrelay.util.badcode[code] then
                discordrelay.log(2,"HTTPRequest",ctx.url,discordrelay.util.badcode[code])
            end
            if not callback then return end
            callback(headers, body, code)
        end,
        ["failed"] = function(reason)
            if not err then return end
            err(reason)
            discordrelay.log(2,"HTTPRequest failed",reason)
        end
    }

    if ctx.body then
        HTTPRequest.body = ctx.body
    elseif ctx.parameters then
        HTTPRequest.parameters = ctx.parameters
    end

    HTTP(HTTPRequest)
end

function discordrelay.WebhookRequest(ctx, callback, err)
    local ctx = ctx
    local HTTPRequest = {
        ["method"] = ctx.method,
        ["url"] = ctx.url,
        ["type"] = "application/json",
        ["headers"] = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = string.len(ctx.body) or "0"
        },
        ["success"] = function(code, body, headers)
            if not callback then return end
            callback(headers, body)
        end,
        ["failed"] = function(reason)
            if not err then return end
            err(reason)
            discordrelay.log(2,"WebhookRequest failed",reason)
        end
    }

    if ctx.body then
        HTTPRequest.body = ctx.body
    elseif ctx.parameters then
        HTTPRequest.parameters = ctx.parameters
    end

    HTTP(HTTPRequest)
end

function discordrelay.util.GetAvatar(steamid, callback)
    local commid = util.SteamIDTo64(steamid)
    local cache = discordrelay.AvatarCache
    if cache[commid] then
        callback(cache[commid])
    else
        http.Fetch("http://steamcommunity.com/profiles/" .. commid .. "?xml=1",
        function(content, size)
            local ret = content:match("<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>") or "http://i.imgur.com/ovW4MBM.png"
            discordrelay.AvatarCache[commid] = ret
            callback(ret)
        end,
        function(err)
            discordrelay.log(3,"GetAvatar failed for:",steamid,err)
        end)
    end
end

function discordrelay.util.IsAdmin(userid, cb)
    discordrelay.HTTPRequest({
        ["method"] = "get",
        ["url"] = discordrelay.endpoints.guilds.."/"..discordrelay.guild.."/members/"..userid
    },
    function(headers, body)
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

function discordrelay.util.startsWith(name, msg, param)
    if not name or not msg then return end
    for k,v in pairs(discordrelay.prefixes) do
        if string.StartWith(msg, v..name) then
            return true
        end
    end
    return false
end

function discordrelay.CreateMessage(channelid, msg, cb)
    local res
    if type(msg) == "string" then
        res = util.TableToJSON({["content"] = msg})
    elseif type(msg) == "table" then
        res = util.TableToJSON(msg)
    else
        return discordrelay.log(3,"Relay: attempting to send a invalid message")
    end
    discordrelay.HTTPRequest({
        ["method"] = "post",
        ["url"] = discordrelay.endpoints.channels.."/"..channelid.."/messages",
        ["body"] = res
    },
    function(headers, body, code)
        if not cb then return end
        local tbl = util.JSONToTable(body)
        cb(headers,tbl,code)
    end,
    function(err)
        discordrelay.log(3,"CreateMessage failed:",channelid,msg,err)
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
        return discordrelay.log(3,"Relay: attempting to send a invalid message")
    end
    discordrelay.WebhookRequest({
        ["method"] = "POST",
        ["url"] = discordrelay.endpoints.webhook.."/"..whid.."/"..whtoken,
        ["body"] = res

    },
    function(headers, body)
        if not cb then return end
        local tbl = util.JSONToTable(body)
        cb(tbl)
    end,
    function(err)
        discordrelay.log(3,"WebhookFailed:",whid,msg,err)
    end)
end

function discordrelay.FetchMembers()
    local url = discordrelay.endpoints.guilds.."/"..(guildid or discordrelay.guild).."/members?limit=1000"
    discordrelay.HTTPRequest({["method"] = "get", ["url"] = url},
    function(headers, body, code)
        if discordrelay.util.badcode[code] then
            discordrelay.log(2,"DiscordRelayFetchMembers failed:",discordrelay.util.badcode[code])
            if code == 502 then
                discordrelay.FetchMembers() -- try again
            else
                return
            end
        end
        for k,v in pairs(util.JSONToTable(body)) do
            discordrelay.members[string.lower(v.user.username)] = v
        end
    end)
end

timer.Create("DiscordRelayFetchMembers", 60*20, 0, discordrelay.FetchMembers)

hook.Add("PostGamemodeLoaded", "DiscordRelayFetchMembersStartup", discordrelay.FetchMembers)

-- modules

local function LoadModule(path)
    if not file.Exists(path,"LUA") then
        discordrelay.log(3,"Modules Error:",path,"not found")
    end
    local func = CompileFile(path)
    if type(func) ~= "string" then
        return func
    end
    return nil
end

function discordrelay.InitializeModules()
    if file.Exists("discordrelay/modules/server","LUA") then
        for _,file in pairs (file.Find("discordrelay/modules/server/*.lua", "LUA")) do
            local name = string.StripExtension(file)
            local func = LoadModule("discordrelay/modules/server/"..file)
            local ok, mod = pcall(func)
            if type(mod) == "string" then
                discordrelay.log(3,"Module Error:",mod,file,"contained errors and will not be loaded!")
                continue
            elseif mod == false then
                discordrelay.log(3,"Module:",file,"NOT loaded. (returned false)")
                continue
            elseif mod == nil then
                 discordrelay.log(3,"Module:",file,"NOT loaded. (no Functions defined)")
                continue
            end
            discordrelay.modules[name] = mod
            if discordrelay.modules[name].Init then
                discordrelay.modules[name].Init()
            else
                discordrelay.log(2,"Discord Module:",name,"not initialized!")
            end
            discordrelay.log(1,"Discord Module:",name,"loaded.")
        end
    end
    if file.Exists("discordrelay/modules/client","LUA") then
        for _,file in pairs (file.Find("discordrelay/modules/client/*.lua", "LUA")) do
            AddCSLuaFile("discordrelay/modules/client/"..file)
        end
    end
end
--discordrelay.InitializeModules()
hook.Add("NotagainPostLoad", "DiscordRelayLoadModules", discordrelay.InitializeModules)

function discordrelay.reload()
    for _,v in pairs(discordrelay.modules) do
        v.Remove()
    end
    discordrelay.InitializeModules()
    discordrelay.members = {}
    discordrelay.FetchMembers()
    if timer.Exists("DiscordRelayFetchMessages") then
        timer.Destroy("DiscordRelayFetchMessages")
    end
    timer.Create("DiscordRelayFetchMessages", 1.5, 0, discordrelay.DiscordRelayFetchMessages)
end

--It was either this or websockets. But this shouldn't be that bad of a solution

local around = 0
local abort = 0


function discordrelay.DiscordRelayFetchMessages()
    if abort >= 5 then discordrelay.log(3,"FetchMessages failed DESTROYING") timer.Destroy("DiscordRelayFetchMessages") return end -- prevent spam
    local url
    if around ~= 0 then
        url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages?limit=3&around="..around
    else
        url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages"
    end
    discordrelay.HTTPRequest({["method"] = "get", ["url"] = url},
    function(headers, body, code)
        if discordrelay.util.badcode[code] then
            abort = abort + 1
            discordrelay.log(2,"FetchMessages failed",discordrelay.util.badcode[code],"retrying",abort)
            return
        else
            abort = 0
        end
        local json = util.JSONToTable(body)

        local previous
        local current
        local future

        -- todo: maybe sort incoming table from discord in case they send the table different?
        if around ~= 0 then
            if #json == 3 then
                current = json[1]
                previous = json[2]
                future = json[3]
            elseif #json == 2 then
                current = json[1]
                previous = json[2]
            end
        else
            current = json[1]
        end

        if current and (around ~= 0 and around ~= current.id) then
            abort = 0
            if discordrelay.user.id == current.author.id or type(current) == "number" then -- ignore the relays own message (CreateMessage)
                around = current.id
                return
            end

            -- if current.webhook_id and current.webhook_id == discordrelay.webhookid then -- our own webhook (messages) skipping..
            --     around = current.id
            --     return
            -- end

            if table.Count(discordrelay.modules) < 1 then
                discordrelay.log(2,"Got Discord response, but no Modules are loaded")
            end

            for name,dmodule in pairs(discordrelay.modules) do
                if dmodule.Handle then
                    local ok,why = pcall(dmodule.Handle,current,previous,future)
                    if not ok then
                        discordrelay.log(3,"Module Error:",name,why)
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
                        if discordrelay.modules[name].Remove then
                            discordrelay.modules[name].Remove()
                        else
                            discordrelay.log(2,"Module Error:",name,"has no remove function and might not be unloaded correctly!")
                            discordrelay.modules[name] = nil -- fallback so it doesn't keep erroring
                        end
                    end
                end
            end
            if current.id > around then
                around = current.id
            end
        elseif not json then
        discordrelay.log(2,"json nil???",code,url)
        elseif not current then
        discordrelay.log(2,"json empty???",code,url)
        elseif not current.id then
        discordrelay.log(2,"json no id???",code,url)
        end
        if json and current and around == 0 then
            around = current.id
        end
    end)
end
--discordrelay.DiscordRelayFetchMessages()
--discordrelay.DiscordRelayFetchMessages()
timer.Create("DiscordRelayFetchMessages", 1.5, 0, discordrelay.DiscordRelayFetchMessages)

hook.Add("ShutDown", "DiscordRelayShutDown", function()
    if discordrelay and discordrelay.enabled then

        discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
            ["username"] = discordrelay.username,
            ["avatar_url"] = discordrelay.avatar,
            ["embeds"] = {
                [1] = {
                    ["title"] = "",
                    ["description"] = "**".. (discordrelay.test and " Test" or " Main") .." Server has shutdown.**",
                    ["type"] = "rich",
                    ["color"] = 0xb30000
                }
            }
        })
    end
end)