if game.SinglePlayer() then ErrorNoHalt("Twitch Interaction may not support singleplayer!")  end
local tgm_ver = "v1.6"
print("TGM version " .. tgm_ver .. " is running, on OS " .. jit.os .. "!")

local didload, sockerr = pcall(function() require("gwsockets") end)
if not didload then
	print(sockerr)
	print("GWSockets did not load the first time, trying again...")
	if _G.GWSockets then PrintTable(_G.GWSockets) print("------ gwsockets is in global table! ------") end
	require("gwsockets") // apparently theres a bug with debian, this should work?
end
//include("actions.lua")

// This controls how fast you receive messages, like the twitch chat and etc
// seems like 0.4 or so is the minimum
local MessageDelay = 0.5
local DebugMode = true
local AutoVoteTimer = CreateConVar("tgm_autovote", "1", FCVAR_ARCHIVE, "If auto vote is enabled.")
local AutoVoteTimerDuration = CreateConVar("tgm_autovoteinterval", "60", FCVAR_ARCHIVE, "How many seconds before an auto vote is triggered.")
local VoteCounter = 0
local socket_connected = false
local socket_reconnect_tries = 0
cvars.AddChangeCallback("tgm_autovote", function(convar, old, new)
	if new == 1 then
		timer.Destroy("AutoVote")
		timer.Create("AutoVote", AutoVoteTimerDuration:GetInt(), 0, function()
			VoteCounter = VoteCounter + 1
			if VoteCounter % 10 == 0 then
				WSFunctions["votetime"].func(true)
			else
				WSFunctions["votetime"].func(false)
			end
		end)
	elseif new == 0 then
		timer.Destroy("AutoVote")
	end
end)
cvars.AddChangeCallback("tgm_autovoteinterval", function(convar, old, new)
	if timer.Exists("AutoVote") then
		timer.Adjust("AutoVote", new)
	end
end)

ChatBossMode = false
ChatBossEnt = nil
ChatBossDamagers = {}

TGM_CurrentViewers = 5
TGM_Streamer = nil

util.AddNetworkString("PrintTwitchChat")
util.AddNetworkString("VoteDerma")
util.AddNetworkString("UpdateDerma")
util.AddNetworkString("EndVoting")
util.AddNetworkString("FuckWithScreen")
util.AddNetworkString("ReverseControls")
util.AddNetworkString("SilentHill")
util.AddNetworkString("ZaWarudoSound")
util.AddNetworkString("PlayCloakSound")
util.AddNetworkString("TimedActionStart")
util.AddNetworkString("Inception")
util.AddNetworkString("SpeedUp")
util.AddNetworkString("SlowDown")
util.AddNetworkString("AntFight")
util.AddNetworkString("Paranoia")
util.AddNetworkString("Thirdperson")
util.AddNetworkString("WhosWho")
util.AddNetworkString("StartTimer")
util.AddNetworkString("ItsAMystery")
util.AddNetworkString("Instakill")
util.AddNetworkString("Kamikaze")
util.AddNetworkString("MobaMode")
util.AddNetworkString("BossMode")
util.AddNetworkString("BossPlayer")
util.AddNetworkString("TankControls")
util.AddNetworkString("RandomSensitivity")
util.AddNetworkString("RandomTexturize")
util.AddNetworkString("RandomOverlay")
util.AddNetworkString("Nearsightedness")
util.AddNetworkString("3DMode")
util.AddNetworkString("MegaBloom")
util.AddNetworkString("MathTime")
util.AddNetworkString("ChatBoss")
util.AddNetworkString("ChangeActionDuration")
util.AddNetworkString("TGM_ChonkyPlayers")
util.AddNetworkString("TGM_UpsidedownPlayers")

do // add files here precache in shared init.lua
	/*for k, v in pairs(file.Find("sound/*", "THIRDPARTY")) do
		resource.AddFile("sound/" .. v)
	end*/
	resource.AddFile("materials/overlays/vignette01.vmt")
end

local tgm_url = CreateConVar("tgm_url", "ws://localhost:8765", FCVAR_ARCHIVE + FCVAR_PROTECTED, "The URL pointing to your websocket. example (ws://localhost:8765)")
local tgm_printvotes = CreateConVar("tgm_printvotes", "0", FCVAR_ARCHIVE, "If the votable actions are printed in Twitch chat.")
WEBSOCKET = WEBSOCKET or GWSockets.createWebSocket(tgm_url:GetString(), false)

function WEBSOCKET:onMessage(txt)
	if txt == "null" then return end
	if string.StartWith(txt, "PrintTwitchChat") then print("Received: PrintTwitchChat") else print("Received: ", txt) end
	if txt == "Serv connect!" then
		//print("connection verified")
	elseif txt == "Test command" then
		//print("Test command received")
	elseif txt == "conntest" then
		//print("conn test!")
	elseif string.StartWith(txt, "AttackBoss") then
		if IsValid(ChatBossEnt) then
			local args = string.Split(txt, ";")
			ChatBossEnt:SetHealth(ChatBossEnt:Health() - args[2])
			PrintMessage(HUD_PRINTTALK, args[3] .. " has dealt " .. args[2] .. " damage to the boss!")
			if not ChatBossDamagers then ChatBossDamagers = {} end
			if ChatBossDamagers[args[3]] then 
				ChatBossDamagers[args[3]] = ChatBossDamagers[args[3]] + args[2]
			else
				ChatBossDamagers[args[3]] = args[2]
			end
			if ChatBossEnt:Health() <= 0 then
				PrintMessage(HUD_PRINTTALK, "The Chat Boss has been slain!")
				PrintMessage(HUD_PRINTTALK, string.format("Most Damage: %i, by %s", ChatBossDamagers[table.GetWinningKey(ChatBossDamagers)] , table.GetWinningKey(ChatBossDamagers)))
				table.Empty(ChatBossDamagers)
			end
		end
	elseif string.StartWith(txt, "PrintTwitchChat") then
		local args = string.Split(txt, "\n")
		//print(args[2]) User
		//print(args[3]) Message
		WSFunctions[string.lower(args[1])].func(args[2], args[3]) // such a fuckin mess
	elseif string.StartWith(txt, "VoteInfo") then
		local args = string.Split(txt, "\n")
		local clean_arg = string.TrimLeft(args[3], "!")
		WSFunctions[string.lower(args[1])].func(args[2], clean_arg)
	elseif string.StartWith(txt, "Viewers") then
		local args = string.Split(txt, ";")
		TGM_CurrentViewers = args[2]
	elseif WSFunctions[string.lower(txt)] and DebugMode and not voting_time then
		print("function found! running")
		WSFunctions[string.lower(txt)].func()
	end
end

function WEBSOCKET:onError(txt)
	print("Error: ", txt)
end

function WEBSOCKET:onConnected()
	print("CONNECTED!")
	socket_connected = true
	socket_reconnect_tries = 0
	PrintMessage(HUD_PRINTTALK, "Websocket connection established!")
	WEBSOCKET:write("Connected Message!")
	if AutoVoteTimer:GetBool() then
		timer.Create("AutoVote", AutoVoteTimerDuration:GetInt(), 0, function()
			VoteCounter = VoteCounter + 1
			if VoteCounter % 10 == 0 then
				WSFunctions["votetime"].func(true)
			else
				WSFunctions["votetime"].func(false)
			end
		end)
	end
	if file.Exists("tgm_streamer.txt", "DATA") then
		local streamer_id = file.Read("tgm_streamer.txt", "DATA")
		TGM_Streamer = player.GetBySteamID(streamer_id)
		if TGM_Streamer == false then
			print("Streamer not found!")
			return
		end
		print(TGM_Streamer:Nick() .. " is the Streamer.")
	end
	
end

function WEBSOCKET:onDisconnected()
	print("disconnected")
	socket_connected = false
	WEBSOCKET:closeNow()
	PrintMessage(HUD_PRINTTALK, "Websocket disconnected.")
	timer.Destroy("CheckIfConnected")
	timer.Destroy("AutoVote")
	timer.Simple(3, function()
		socket_reconnect_tries = socket_reconnect_tries + 1
		print("trying to reconnect... try:" .. socket_reconnect_tries)
		if WEBSOCKET:isConnected() or socket_connected then 
			print("reconnected!")
		elseif socket_reconnect_tries < 3 then
			WEBSOCKET:open()
		end
	end)
end

hook.Add("InitPostEntity", "OpenSocket", function()
	if file.Exists("tgm_actioncounter.txt", "DATA") then
		SetGlobalInt("ActionCounter", file.Read("tgm_actioncounter.txt", "DATA"))
	end
	if WEBSOCKET:isConnected() or socket_connected then return end
	timer.Simple(5, function()
		if WEBSOCKET:isConnected() or socket_connected then return end
		WEBSOCKET:open()
		timer.Simple(2, function()
			if WEBSOCKET:isConnected() or socket_connected then return end
			for k, v in ipairs(player.GetAll()) do
				v:ChatPrint("Websocket connection unsuccessful, read console!")
			end
		end)
	end)
end)

hook.Add("ShutDown", "CloseSocket", function()
	WEBSOCKET:closeNow()
	file.Write("tgm_actioncounter.txt", GetGlobalInt("ActionCounter", 0) % 10)
	local actions = ""
	for key, _ in pairs(WSFunctions) do
		actions = actions .. key .. ";" .. tostring(WSFunctions[key].enabled) .. "\n" // this is A LOT of string making not a good idea
	end
	file.Write("tgm_actions.txt", actions)
end)

hook.Add("PlayerSay", "ChangeSettings", function(sender, txt, teamchat)
	local args = string.Split(txt, " ")
	args[1] = string.lower(args[1])
	if args[1] == "!reconnectsocket" then
		if sender:IsAdmin() then
			if WEBSOCKET:isConnected() or socket_connected then
				WEBSOCKET:close()
				timer.Simple(1, function()
					WEBSOCKET:open()
				end)
			else
				WEBSOCKET:open()
			end
		end
	elseif args[1] == "!forcereconnect" then
		if sender:IsAdmin() then
			if WEBSOCKET then
				WEBSOCKET:close()
				WEBSOCKET = nil
				WEBSOCKET = GWSockets.createWebSocket(tgm_url:GetString(), false)
				WEBSOCKET:open()
			else
				WEBSOCKET = GWSockets.createWebSocket(tgm_url:GetString(), false)
				WEBSOCKET:open()
			end
		end
	elseif args[1] == "!disconnect" then
		if sender:IsAdmin() then
			WEBSOCKET:write("shutdown")
			WEBSOCKET:close()
		end
		return ""
	elseif args[1] == "!connect" then
		if sender:IsAdmin() then
			WEBSOCKET:open()
		end
		return ""
	elseif args[1] == "!anarchymode" then
		if sender:IsAdmin() then
			WEBSOCKET:write("anarchymode")
		end
	elseif args[1] == "!democracymode" then
		if sender:IsAdmin() then
			WEBSOCKET:write("democracymode")
		end
	elseif args[1] == "!actioncounter" then
		if sender:IsAdmin() then
			if tonumber(args[2]) then
				SetGlobalInt("ActionCounter", tonumber(args[2]))
			else
				print(GetGlobalInt("ActionCounter", 0))
			end
		end
		return ""
	elseif args[1] == "!doubleaction" then
		if sender:IsAdmin() then
			if (args[2] and args[3]) and (WSFunctions[args[2]] and WSFunctions[args[3]]) then
				WSFunctions[args[2]].func()
				WSFunctions[args[3]].func()
			end
		end
		return ""
	elseif args[1] == "!disablevoting" then
		if sender:IsAdmin() then
			timer.Destroy("AutoVote")
		end
		return "Voting disabled."
	elseif args[1] == "!enablevoting" then
		if sender:IsAdmin() then
			timer.Create("AutoVote", AutoVoteTimerDuration:GetInt(), 0, function()
				VoteCounter = VoteCounter + 1
				if VoteCounter % 10 == 0 then
					WSFunctions["votetime"].func(true)
				else
					WSFunctions["votetime"].func(false)
				end
			end)
		end
		return "Voting enabled."
	elseif args[1] == "!disableaction" then
		if sender:IsAdmin() then
			if (args[2]) then
				if WSFunctions[args[2]] then
					print(args[2] .. " has been disabled.")
					WSFunctions[args[2]].enabled = false
				else
					print(args[2] .. " is not a valid action!")
				end
			end
		end
		return ""
	elseif args[1] == "!enableaction" then
		if sender:IsAdmin() then
			if (args[2]) then
				if WSFunctions[args[2]] then
					print(args[2] .. " has been enabled.")
					WSFunctions[args[2]].enabled = true
				else
					print(args[2] .. " is not a valid action!")
				end
			end
		end
		return ""
	elseif args[1] == "!printactions" then
		if sender:IsAdmin() then
			print(" ---------------------------- ")
			for k, v in pairs(WSFunctions) do
				if not v.enabled then continue end
				if PrettyFuncs[k] then
					print(k .. " : " .. PrettyFuncs[k])
				else
					print(k .. " : HAS NO PRETTYFUNC!")
				end
			end
			print(" ---------------------------- ")
		end
		return "Check console."
	elseif args[1] == "!printdisabledactions" then
		if sender:IsAdmin() then
			print(" ---------------------------- ")
			for k, v in pairs(WSFunctions) do
				if v.enabled then continue end
				if PrettyFuncs[k] then
					print(k .. " : " .. PrettyFuncs[k])
				else
					print(k .. " : HAS NO PRETTYFUNC!")
				end
			end
			print(" ---------------------------- ")
		end
		return "Check console."
	elseif args[1] == "!attack" then
		if ChatBossMode then
			ChatBossEnt:SetHealth(ChatBossEnt:Health() - 1)
			PrintMessage(HUD_PRINTTALK, sender:Nick() .. " has dealt " .. 1 .. " damage to the boss!")
			if not ChatBossDamagers then ChatBossDamagers = {} end
			if ChatBossDamagers[args[3]] then 
				ChatBossDamagers[sender:Nick()] = ChatBossDamagers[sender:Nick()] + 1
			else
				ChatBossDamagers[sender:Nick()] = 1
			end
			if ChatBossEnt:Health() <= 0 then
				PrintMessage(HUD_PRINTTALK, "The Chat Boss has been slain!")
				PrintMessage(HUD_PRINTTALK, string.format("Most Damage: %i, by %s", ChatBossDamagers[table.GetWinningKey(ChatBossDamagers)] , table.GetWinningKey(ChatBossDamagers)))
				table.Empty(ChatBossDamagers)
			end
		end
		return ""
	elseif args[1] == "!streamer" then
		TGM_Streamer = sender
		PrintMessage(HUD_PRINTTALK, TGM_Streamer:Nick() .. " has been set as the Streamer.")
		file.Write("tgm_streamer.txt", TGM_Streamer:SteamID())
		WSFunctions["spbossmode"].enabled = true
		return ""
	elseif WSFunctions[string.TrimLeft(args[1], "!")] then
		print("function found in PlayerSay, running...")
		local clean_command = string.TrimLeft(args[1], "!")

		if not args[2] then
			if voting_time then
				if WSFunctions[clean_command] then
					WSFunctions["voteinfo"].func(sender:Nick(), clean_command)
				end
			else
				if not sender:IsAdmin() then return "" end
				WSFunctions[clean_command].func()
				IncrementActionCounter()
			end
		else
			if not sender:IsAdmin() then return "" end
			if args[2] == "true" or args[2] == "false" then args[2] = tobool(args[2]) else return "" end
			WSFunctions[clean_command].func(args[2])
			IncrementActionCounter()
		end

		return ""
	elseif args[1] == "!1" or args[1] == "!2" or args[1] == "!3" or args[1] == "!4" then
		if voting_time then
			WSFunctions["voteinfo"].func(sender:Nick(), string.TrimLeft(args[1], "!"))
		end
		return ""
	end
end)