-- local discordrelay = {}
-- local discordrelay.modules = discordrelay.modules or {}

-- -- modules
-- if file.Exists("discordrelay/modules/client","LUA") then
--     for _,file in pairs (file.Find("discordrelay/modules/client/*", "LUA")) do
--         local name = string.StripExtension(file)
--         local func = CompileFile("discordrelay/modules/client/"..file)
--         local ok, mod = pcall(func)
--         if type(mod) == "string" then
--             print("err: ",mod,file)
--         end
--         if not ok then return end
--         discordrelay.modules[name] = func
--     end
-- end

--todo clientside modules????????

-- standard message
local allowmsg = CreateClientConVar( "cl_discordrelay", "1", true, false )

net.Receive( "DiscordMessage", function()
	if not allowmsg:GetBool() then return end

	local nick = net.ReadString()
	local message = net.ReadString()

	if ChathudImage then
		ChathudImage(message)
	end

	local ok = hook.Run("OnDiscordMessage",nick,message)
	if ok == false then return end
	if nick ~= "" then
		chat.AddText( Color(114,137,218,255), "[Discord] "..nick, Color(255,255,255,255),": "..message)
	else
		chat.AddText(Color(255,255,255,255), message)
	end
end)
