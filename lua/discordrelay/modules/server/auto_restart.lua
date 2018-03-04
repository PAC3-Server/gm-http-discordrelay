local auto_restart = {}
local discordrelay = discordrelay

function auto_restart.Init()
	hook.Add("AutoRestart", "DiscordrelayAutoRestartMsg", function(forced, reason)
		discordrelay.notify("Auto Restart trigger: " .. (reason and ("pending updates from " .. reason) or (forced and "last restart was over 6 hours ago")) or "???")
	end)
end

function auto_restart.Remove()
	hook.Remove("AutoRestart", "DiscordrelayAutoRestartMsg")
	if discordrelay.modules.auto_restart then
		discordrelay.modules.auto_restart = nil
	end
end

return auto_restart