if game.SinglePlayer() then error("Twitch Interaction cant be run in singleplayer!") return end

require("gwsockets")
//include("actions.lua")
print("runnin!")

// This controls how fast you receive messages, like the twitch chat and etc
// seems like 0.4 or so is the minimum
local MessageDelay = 0.5
local DebugMode = true
local AutoVoteTimer = true
local AutoVoteTimerDuration = 60
local VoteCounter = 0

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

do // add files here precache in shared init.lua
	/*for k, v in pairs(file.Find("sound/*", "THIRDPARTY")) do
		resource.AddFile("sound/" .. v)
	end*/
	resource.AddFile("materials/overlays/vignette01.vmt")
end

local tgm_url = CreateConVar("tgm_url", "ws://localhost:8765", FCVAR_ARCHIVE + FCVAR_PROTECTED, "The URL pointing to your websocket. example (ws://localhost:8765)")
WEBSOCKET = WEBSOCKET or GWSockets.createWebSocket(tgm_url:GetString(), false)

function WEBSOCKET:onMessage(txt)
	if txt == "null" then return end
	print("Received: ", txt)
	if txt == "Serv connect!" then
		//print("connection verified")
	elseif txt == "Test command" then
		//print("Test command received")
	elseif txt == "conntest" then
		//print("conn test!")
	elseif string.StartWith(txt, "PrintTwitchChat") then
		local args = string.Split(txt, "\n")
		//print(args[2]) User
		//print(args[3]) Message
		WSFunctions[string.lower(args[1])](args[2], args[3]) // such a fuckin mess
	elseif string.StartWith(txt, "VoteInfo") then
		local args = string.Split(txt, "\n")
		local clean_arg = string.TrimLeft(args[3], "!")
		WSFunctions[string.lower(args[1])](args[2], clean_arg)
	elseif WSFunctions[string.lower(txt)] and DebugMode and not voting_time then
		print("function found! running")
		WSFunctions[string.lower(txt)]()
	end
end

function WEBSOCKET:onError(txt)
	print("Error: ", txt)
end

function WEBSOCKET:onConnected()
	print("CONNECTED!")
	for k, v in ipairs(player.GetAll()) do
		v:ChatPrint("Websocket connection established!")
	end
	WEBSOCKET:write("Connected Message!")
	timer.Create("CheckIfConnected", MessageDelay, 0, function()
		//print("testing for connection")
		WEBSOCKET:write("ConnTest")
	end)
	if AutoVoteTimer then
		timer.Create("AutoVote", AutoVoteTimerDuration, 0, function()
			VoteCounter = VoteCounter + 1
			if VoteCounter % 10 == 0 then
				WSFunctions["votetime"](true)
			end
			WSFunctions["votetime"](false)
		end)
	end
end

function WEBSOCKET:onDisconnected()
	print("disconnected")
	timer.Destroy("CheckIfConnected")
	timer.Destroy("AutoVote")
end

hook.Add("InitPostEntity", "OpenSocket", function()
	if file.Exists("twitch_interact.txt", "DATA") then
		SetGlobalInt("ActionCounter", file.Read("twitch_interact.txt", "DATA"))
	end
	if WEBSOCKET:isConnected() then return end
	timer.Simple(10, function()
		if WEBSOCKET:isConnected() then return end
		WEBSOCKET:open()
		timer.Simple(2, function()
			if WEBSOCKET:isConnected() then return end
			for k, v in ipairs(player.GetAll()) do
				v:ChatPrint("Websocket connection unsuccessful, read console!")
			end
		end)
	end)
end)

hook.Add("ShutDown", "CloseSocket", function()
	local counter_exists = sql.Query( "SELECT * FROM twitch_interact" )
	file.Write("twitch_interact.txt", GetGlobalInt("ActionCounter", 0) % 10)
	WEBSOCKET:write("shutdown")
	WEBSOCKET:close()
end)

hook.Add("PlayerSay", "ChangeSettings", function(sender, txt, teamchat)
	local args = string.Split(txt, " ")
	args[1] = string.lower(args[1])
	if args[1] == "!changedelay" then
		MessageDelay = args[2]
		print("BEFORE - -- -- - - -- - --" .. MessageDelay)
		timer.Adjust("CheckIfConnected", MessageDelay, 0, function()
			WEBSOCKET:write("ConnTest")
		end)
		timer.Start("CheckIfConnected")
		print("AFTER - -- - - -- - - -" .. MessageDelay)
	elseif args[1] == "!reconnectsocket" then
		if sender:IsAdmin() then
			if WEBSOCKET:isConnected() then
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
	elseif args[1] == "!changewsurl" then
		if sender:IsAdmin() then
			tgm_url:SetString(args[2])
			print("setting url to ".. tgm_url:GetString())
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
				WSFunctions[args[2]]()
				WSFunctions[args[3]]()
			end
		end
		return ""
	elseif WSFunctions[string.TrimLeft(args[1], "!")] then
		print("function found in PlayerSay, running...")
		local clean_command = string.TrimLeft(args[1], "!")

		if not args[2] then
			if voting_time then
				if WSFunctions[clean_command] then
					PrintMessage(HUD_PRINTTALK, sender:Nick() .. " has voted for " .. PrettyFuncs[clean_command])
					WSFunctions["voteinfo"](sender:Nick(), clean_command)
				end
			else
				if not sender:IsAdmin() then return "" end
				WSFunctions[clean_command]()
				IncrementActionCounter()
			end
		else
			if not sender:IsAdmin() then return "" end
			if args[2] == "true" or args[2] == "false" then args[2] = tobool(args[2]) else return "" end
			WSFunctions[clean_command](args[2])
			IncrementActionCounter()
		end

		return ""
	end
end)