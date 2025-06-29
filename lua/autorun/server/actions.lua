print("Actions file load!")
WSFunctions = WSFunctions or {}
WSFunctions_disabled = WSFunctions_disabled or {}
local votable_funcs = {}
voting_time = false

//local max_votable_funcs = 2

/* ACTION VARIABLES */
local isSlapping = false
local ParanoiaVar = false
local DeafnessVar = false
local InstakillVar = false
local speedup = false
local slowdown = false
local TimeSkipTab = TimeSkipTab or {}
local bouncyJump = false
local goodnightGirl = false
local PhoonMode = false

local DebugMode = false

local KamikazeVar = false
local KamikazePlayer = nil
local KamikazeMarker = nil

local _gamemode = GetConVar("gamemode"):GetString()

/* HOOKS */
hook.Add("Move", "Speedup or Slowdown", function(ply, mv)
	if speedup or ply.Kamikaze or ply.WhosWho or ply.IsBoss or PhoonMode then
		local speed = mv:GetMaxSpeed() * 2.5
		mv:SetMaxSpeed(speed)
		mv:SetMaxClientSpeed(speed)
	end
	if slowdown then
		local speed = mv:GetMaxSpeed() / 2
		mv:SetMaxSpeed(speed)
		mv:SetMaxClientSpeed(speed)
	end
end)

hook.Add("GetFallDamage", "SlapOverwrite", function(ply, speed)
	if isSlapping or bouncyJump or PhoonMode then
		return 0
	end
end)

hook.Add("EntityTakeDamage", "FallDamagePrevent", function(ent, dmginfo)
	if IsValid(ent) and ent:IsPlayer() and dmginfo:IsFallDamage() then
		if isSlapping or bouncyJump or goodnightGirl or PhoonMode then
			dmginfo:ScaleDamage(0.2)
			if (dmginfo:GetDamage() > 20) then
				dmginfo:SetDamage(20)
			end
		end
	end
end)

hook.Add("VotingStarted", "TimeSkipRec", function()
	table.Empty(TimeSkipTab)
	for k, v in ipairs(player.GetAll()) do
		table.insert(TimeSkipTab, {eyeangles = v:EyeAngles(), pos = v:GetPos(), wasAlive = v:Alive()})
		GetPlayerInfoTGM(v)
	end
end)

local function TGMCalcHear(listener, talker)
	if DeafnessVar then
		return false
	end
end

hook.Add("PlayerCanHearPlayersVoice", "ParanoiaDisableVoice", TGMCalcHear)

local function GetAlivePlayers()
	local alivePlayers = {}
	for k, v in ipairs(player.GetAll()) do
		if v:Alive() then table.insert(alivePlayers, v) end
	end

	return alivePlayers
end

hook.Add("EntityTakeDamage", "TGMTakeDamage", function(target, dmginfo)
	if InstakillVar then
		dmginfo:ScaleDamage(9999)
	end
	if target:IsPlayer() and target.Kamikaze then
		dmginfo:ScaleDamage(0.2)
	end
	if target:IsPlayer() and target.WhosWho then
		dmginfo:ScaleDamage(0)
	end
	if target:IsPlayer() and target.IsBoss then
		dmginfo:ScaleDamage(1 / #GetAlivePlayers())
	end
end)

local function AddAllPlayersToVis(tab)
	// tab should be players.getall or GetAlivePlayers
	for k, v in ipairs(tab) do
		AddOriginToPVS(v:GetPos())
	end
end

local function HandleKamikazeDeath(ply, marker)
	KamikazePlayer = nil
	KamikazeMarker = nil
	ply:StopSound("kamikaze_scream")
	ply:StopSound("mario_screaming")
	KamikazeVar = false
	ply.Kamikaze = false
	marker:Remove()
	timer.Remove("KamikazeExplode")
end

function GetBossPlayers()
	local bosses = {}
	for k, v in ipairs(GetAlivePlayers()) do
		if v.IsBoss then table.insert(bosses, v) end
	end

	return bosses
end

hook.Add("PlayerDeath", "TGMPlayerDeath", function(victim, inflictor, attacker)
	if victim == KamikazePlayer then
		print("The Kamikaze has been slain!")
		HandleKamikazeDeath(victim, KamikazeMarker)
	end
	if victim.IsBoss then
		victim.IsBoss = false
		net.Start("BossPlayer")
			net.WriteBool(false)
		net.Send(victim)
		PrintMessage(HUD_PRINTTALK, "The Boss " .. victim:Nick() .. " has been slain!")
		if #GetBossPlayers() == 0 then
			net.Start("BossMode")
				net.WriteBool(false)
			net.Broadcast()
		end
	end
end)

hook.Add("SetupPlayerVisibility", "TGMVis", function(pPlayer, viewentity)
	if KamikazeVar then
		if pPlayer.Kamikaze then
			AddAllPlayersToVis(GetAlivePlayers())
		else
			AddOriginToPVS(KamikazePlayer:GetPos())
		end
	end
	if pPlayer.IsBoss then
		AddAllPlayersToVis(GetAlivePlayers())
	end
	if ChatBossMode and IsValid(ChatBossEnt) then
		AddOriginToPVS(ChatBossEnt:GetPos())
	end
end)

local function SendTimer(broadcast, plys, time)
	broadcast = broadcast or false
	time = time or GetActionDuration()
	plys = plys or player.GetAll()

	if broadcast then
		net.Start("StartTimer")
			net.WriteFloat(time)
		net.Broadcast()
	else
		net.Start("StartTimer")
			net.WriteFloat(time)
		net.Send(plys)
	end
end

function GetEnabledActions()
	local result = {}
	for k, v in pairs(WSFunctions) do
		if not v.enabled then continue end
		result[k] = v
	end
	return result
end

function GetDisabledActions()
	local result = {}
	for k, v in pairs(WSFunctions) do
		if v.enabled then continue end
		result[k] = v
	end
	return result
end

/* ACTIONS */
local function RandomizeViews()
	print("randomizing views")
	local plys = GetAlivePlayers()
	SendTimer(false, plys, GetActionDuration())
	local plyAngles = {}
	for k, v in ipairs(plys) do
		plyAngles[k] = v:EyeAngles()
		v:SetEyeAngles(AngleRand())
	end
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			v:SetEyeAngles(Angle(plyAngles[k].pitch, plyAngles[k].yaw, 0))
		end
	end)
	// set all player viewangles to random vectors
end

local function LowerGravity()
	print("lowering gravity")
	SendTimer(true)
	local oldgrav = physenv.GetGravity() // default grav is Vector(0, 0, -600)
	print(oldgrav)
	local oldnumgrav = GetConVar("sv_gravity"):GetInt()
	RunConsoleCommand("sv_gravity", "200")
	timer.Simple(GetActionDuration(), function()
		RunConsoleCommand("sv_gravity", oldnumgrav)
	end)
	//physenv.SetGravity(Vector())
	// lower gravity real low
end

local function DeepFry()
	print("deep frying")
	SendTimer(true)
	// server to client, fuck up saturation and contrast an shit
	net.Start("FuckWithScreen")
	net.Broadcast()
	local plys = player.GetAll()
	for k, v in ipairs(plys) do
		v:SetDSP(38, false)
	end
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			v:SetDSP(1, false)
		end
	end)
end

local function Inception()
	print("bwaaam. inception time")
	SendTimer(true)
	//local oldnumgrav = GetConVar("sv_gravity"):GetInt()
	// lower gravity below 0 for a period of time, then bring it back to normal
	RunConsoleCommand("sv_gravity", "80")
	RunConsoleCommand("sv_airaccelerate", "1000")
	RunConsoleCommand("sv_sticktoground", "0")
	net.Start("Inception")
	net.Broadcast()
	for k, v in ipairs(GetAlivePlayers()) do
		local power = 100
		local direction = Vector( math.random( 5 )-10, math.random( 5 )-10, math.random( 5 ) )
		if not v:Alive() then
			return
		end
		local accel = power
		accel = direction * accel
		v:SetVelocity( accel )
	end
	timer.Simple(GetActionDuration(), function()
		RunConsoleCommand("sv_gravity", "600")
		RunConsoleCommand("sv_airaccelerate", "10")
		RunConsoleCommand("sv_sticktoground", "1")
	end)
end

local function newZombie(pos, ang, ply, b) // ulib again
	local ent = ents.Create( "npc_zombie" )
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()
	ent:AddRelationship("player D_HT 98") 
	ent:AddEntityRelationship( ply, D_HT, 99 ) -- Hate target

	return ent
end

local function SpawnZombies() // ulib
	print("spawning zombies")
	local plys = GetAlivePlayers()
	for k, v in ipairs(plys) do
		local pos = {}
		local testent = newZombie( Vector( 0, 0, 0 ), Angle( 0, 0, 0 ), v, true ) -- Test ent for traces

		local yawForward = v:EyeAngles().yaw
		local direction = math.NormalizeAngle( yawForward - 180 )

		local t = {}
		t.start = v:GetPos() + Vector( 0, 0, 32 ) -- Move them up a bit so they can travel across the ground
		t.filter = { v, testent }

		t.endpos = v:GetPos() + Angle( 0, direction, 0 ):Forward() * 47 -- (33 is player width, this is sqrt( 33^2 * 2 ))
		local tr = util.TraceEntity( t, testent )

		if not tr.Hit then
			table.insert( pos, v:GetPos() + Angle( 0, direction, 0 ):Forward() * 47 )
		end

		testent:Remove() -- Don't forget to remove our friend now!

		if #pos > 0 then
			for _, newpos in ipairs( pos ) do
				local newang = (v:GetPos() - newpos):Angle()

				local ent = newZombie( newpos, newang, v )
			end
		else
			v:ChatPrint("No suitable position for zombie.")
		end
	end
end

local function PrintTwitchChat(user, message)
	local plys = {}
	for k, v in pairs(player.GetAll()) do
		if v:GetInfoNum("tgm_chat", 0) == 1 then
			table.insert(plys, v)
		end
	end
	net.Start("PrintTwitchChat")
		net.WriteString(user)
		net.WriteString(message)
	net.Send(plys)
end

local function MasterFOV()
	print("OH ILL SHOW YA MASTER FOV")
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	local plyFovs = {}
	for k, v in pairs(plys) do
		plyFovs[k] = v:GetFOV()
		v:SetFOV(177, 1)
		v:ChatPrint("MASTER FOV ENGAGED")
	end
	timer.Create("MasterFOV", 1, GetActionDuration() - 1, function()
		for k, v in pairs(plys) do
			v:SetFOV(177, 1)
		end
	end)
	timer.Simple(GetActionDuration(), function()
		for k, v in pairs(plys) do
			v:SetFOV(plyFovs[k], 1)
		end
		timer.Destroy("MasterFOV")
	end)
end

local function GetWinnerKey(tab)
	local highest = -math.huge
	local winner = nil

	for k, v in ipairs(tab) do
		if v.value > highest then
			winner = k
			highest = tab[k].value
		end
	end

	return winner
end

local function GetVotableFuncs(tab, isDoubleVote)
	local used_funcs = {}

	while #tab != 4 do
		local func, key = table.Random(GetEnabledActions())

		if key == "printtwitchchat" or key == "voteinfo" or key == "votetime" then
			continue
		else
			if isDoubleVote then  // if it is a double vote
				local func2, key2 = table.Random(WSFunctions)
				if key2 == key then continue end

				// i hate this if statement so much...
				if key2 == "printtwitchchat" or key2 == "voteinfo" or key2 == "votetime" then 
					continue
				else
					if table.HasValue(used_funcs, key) or table.HasValue(used_funcs, key2) then continue end
					used_funcs[#used_funcs + 1] = key
					used_funcs[#used_funcs + 1] = key2
					tab[#tab + 1] = {name = key, name2 = key2, value = 0}
				end
			else // if it is a normal vote
				if table.HasValue(used_funcs, key) then continue end
				used_funcs[#used_funcs + 1] = key
				tab[#tab + 1] = {name = key, value = 0}
			end
		end
	end
	PrintTable(used_funcs)
end

//AutoVote
local function VoteTime(isDoubleVote)
	if not isDoubleVote then isDoubleVote = false end
	if not voting_time then
		WEBSOCKET:write("VoteTime")
		print("voting time!")
		hook.Run("VotingStarted")
		voting_time = true

		math.randomseed(os.time())
		GetVotableFuncs(votable_funcs, isDoubleVote)
		if WEBSOCKET and WEBSOCKET:isConnected() and GetConVar("tgm_printvotes"):GetBool() then
			local ws_actions = ""
			for k, v in pairs(votable_funcs) do
				ws_actions = ws_actions .. PrettyFuncs[v.name] .. " (!" .. v.name .. ");" // hate this
			end
			print("sending actions")
			WEBSOCKET:write("VoteActions;" .. ws_actions)
		else
			print("websocket not there or connected, so not sending voteactions")
		end

		local json = util.TableToJSON(votable_funcs)
		local data = util.Compress(json)

		net.Start("VoteDerma")
			if isDoubleVote then net.WriteBool(true) else net.WriteBool(false) end
			net.WriteUInt(#data, 16)
			net.WriteData(data, #data)
		net.Broadcast()

		net.Start("UpdateDerma")
				net.WriteUInt(#data, 16)
				net.WriteData(data, #data)
		net.Broadcast()

		SendTimer(true)

		timer.Create("UpdateMenu", GetActionDuration() / 30, 30 - 1, function()
			local json = util.TableToJSON(votable_funcs)
			local data = util.Compress(json)
			net.Start("UpdateDerma")
				net.WriteUInt(#data, 16)
				net.WriteData(data, #data)
			net.Broadcast()
		end)
		// open a derma menu on clientside and send json of the votes
		timer.Simple(GetActionDuration(), function()
			print("voting time over!")
			hook.Run("VotingEnded")
			PrintTable(votable_funcs)
			WEBSOCKET:write("VoteOver")
			local winning_func_key = GetWinnerKey(votable_funcs)
			local winning_func = votable_funcs[winning_func_key].name
			if isDoubleVote then
				local winning_func2 = votable_funcs[winning_func_key].name2
				print(winning_func .. " " .. winning_func2)
				PrintMessage(HUD_PRINTTALK, PrettyFuncs[winning_func] .. " and " .. PrettyFuncs[winning_func2])
				if not WSFunctions[winning_func] then ErrorNoHalt("Function " .. winning_func .. " doesn't exist!") return end
				if not WSFunctions[winning_func2] then ErrorNoHalt("Function " .. winning_func2 .. " doesn't exist!") return end
				WSFunctions[winning_func].func()
				WSFunctions[winning_func2].func()
			else
				print(winning_func)
				PrintMessage(HUD_PRINTTALK, PrettyFuncs[winning_func])
				if not WSFunctions[winning_func] then ErrorNoHalt("Function " .. winning_func .. " doesn't exist!") return end
				WSFunctions[winning_func].func()
			end
			IncrementActionCounter()
			
			table.Empty(votable_funcs)
			voting_time = false

			net.Start("EndVoting")
			net.Broadcast()
		end)
	end
end

/*local function ContainsFunc(tab, func)
	for k, v in pairs(tab) do
		if v.name == func then
			//print(v.name .. " = " .. func)
			return true
		else
			//print(v.name .. " != " .. func)
			continue
		end
	end
	if func == "1" or func == "2" or func == "3" or func == "4" then return true // !1-4 to vote instead of typing the name
	return false
end

local function GetKey(tab, func)
	for k, v in pairs(tab) do
		if v.name == func then
			return k
		end
	end
end*/

local function VoteInfo(user, message)
	print("info received")
	message = tonumber(message)
	if not votable_funcs[message] then return end
	PrintMessage(HUD_PRINTTALK, string.gsub(user, "^%l", string.upper) .. " has voted for " .. PrettyFuncs[votable_funcs[message].name])
	votable_funcs[message].value = votable_funcs[message].value + 1
	//PrintTable(votable_funcs)
end

local function ZaWarudo() // from Vipes, edited for personal use https://steamcommunity.com/id/lordvipes
	print("ZA WARUDO")
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	// look at the addon
	net.Start("ZaWarudoSound")
		net.WriteBool(true)
	net.Broadcast()
	timer.Create("TheWorld", 2, 1, function()
		RunConsoleCommand( "phys_timescale", "0" )
		RunConsoleCommand( "ai_disabled", "1" )
		RunConsoleCommand( "ragdoll_sleepaftertime", "0" )
		math.randomseed(os.time())
		local randplayer = plys[math.random(#plys)]
		for k, v in pairs(plys) do
			if v:Alive() and (v != randplayer) then
				print(v:Nick())
				v:Freeze( true )
				v:SetMoveType(MOVETYPE_NOCLIP)
				v:ScreenFade( SCREENFADE.OUT, Color(0, 0, 0), 1, GetActionDuration() - 1) // this should be cool than just a screenfade
			end
		end
		timer.Create("stoppedTime", GetActionDuration() - 1, 1, function()
			net.Start("ZaWarudoSound")
				net.WriteBool(false)
			net.Broadcast()
			timer.Create("StartTime", 1, 1, function()
				RunConsoleCommand( "phys_timescale", "1" )
				RunConsoleCommand( "ai_disabled", "0" )
				RunConsoleCommand( "ragdoll_sleepaftertime", "5" )
				for k, v in pairs(plys) do
					v:Freeze( false )
					v:SetMoveType(MOVETYPE_WALK)
				end
			end)
		end)
	end)
end

local function InvisibleWarfare()
	print("making everyone invisible!")
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("PlayCloakSound")
		net.WriteBool(true)
	net.Broadcast()
	for k, ply in ipairs(plys) do // from ulib https://github.com/TeamUlysses/ulib/blob/master/LICENSE.md -- changes were made 
		local visibility = 0
		ply:DrawShadow( false )
		ply:SetMaterial( "models/effects/vol_light001" )
		ply:SetRenderMode( RENDERMODE_TRANSALPHA )
		ply:Fire( "alpha", visibility, 0 )
		ply:GetTable().invis = { vis=visibility, wep=ply:GetActiveWeapon() }

		if IsValid( ply:GetActiveWeapon() ) then
			ply:GetActiveWeapon():SetRenderMode( RENDERMODE_TRANSALPHA )
			ply:GetActiveWeapon():Fire( "alpha", visibility, 0 )
			ply:GetActiveWeapon():SetMaterial( "models/effects/vol_light001" )
			if ply:GetActiveWeapon():GetClass() == "gmod_tool" then
				ply:DrawWorldModel( false ) -- tool gun has problems
			else
				ply:DrawWorldModel( true )
			end
		end
	end
	timer.Simple(GetActionDuration(), function()
		net.Start("PlayCloakSound")
			net.WriteBool(false)
		net.Broadcast()
		for k, ply in ipairs(plys) do
			ply:DrawShadow( true )
			ply:SetMaterial( "" )
			ply:SetRenderMode( RENDERMODE_NORMAL )
			ply:Fire( "alpha", 255, 0 )
			local activeWeapon = ply:GetActiveWeapon()
			if IsValid( activeWeapon ) then
				activeWeapon:SetRenderMode( RENDERMODE_NORMAL )
				activeWeapon:Fire( "alpha", 255, 0 )
				activeWeapon:SetMaterial( "" )
			end
			ply:GetTable().invis = nil
		end
	end)
end

function GetPlayerInfoTGM(player) // from ulib
	local t = {}
	if not player:Alive() then return end
	player.SpawnInfo = t
	t.health = player:Health()
	t.armor = player:Armor()
	if player:GetActiveWeapon():IsValid() then
		t.curweapon = player:GetActiveWeapon():GetClass()
	end

	local weapons = player:GetWeapons()
	local data = {}
	for _, weapon in ipairs( weapons ) do
		printname = weapon:GetClass()
		data[ printname ] = {}
		data[ printname ].clip1 = weapon:Clip1()
		data[ printname ].clip2 = weapon:Clip2()
		data[ printname ].ammo1 = player:GetAmmoCount( weapon:GetPrimaryAmmoType() )
		data[ printname ].ammo2 = player:GetAmmoCount( weapon:GetSecondaryAmmoType() )
	end
	t.data = data
end

function DoWeapons( player, t )
	if not player:IsValid() then return end // also from Ulib

	player:StripAmmo()
	player:StripWeapons()

	for printname, data in pairs( t.data ) do
		player:Give( printname )
		local weapon = player:GetWeapon( printname )
		if not weapon.SetClip1 or not weapon.SetClip2 then continue end
		weapon:SetClip1( data.clip1 )
		weapon:SetClip2( data.clip2 )
		player:SetAmmo( data.ammo1, weapon:GetPrimaryAmmoType() )
		player:SetAmmo( data.ammo2, weapon:GetSecondaryAmmoType() )
	end

	if t.curweapon then
		player:SelectWeapon( t.curweapon )
	end
end

function SpawnPlayer(player)
	if _gamemode == "terrortown" then
		player:SpawnForRound(true)
	else
		player:Spawn()
	end
	
	if player.SpawnInfo then
		local t = player.SpawnInfo
		player:SetHealth( t.health )
		player:SetArmor( t.armor )
		timer.Simple( 0.1, function() DoWeapons( player, t ) end )
		player.SpawnInfo = nil
	end
end

local function RagdollEveryone()
	print("ragdolling everyone!")
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	for k, v in ipairs(plys) do
		if v:Alive() then
			GetPlayerInfoTGM(v)

			local ragdoll = ents.Create( "prop_ragdoll" )
			ragdoll.ragdolledPly = v

			ragdoll:SetPos( v:GetPos() )
			local velocity = v:GetVelocity()
			ragdoll:SetAngles( v:GetAngles() )
			ragdoll:SetModel( v:GetModel() )
			ragdoll:Spawn()
			ragdoll:Activate()
			v:SetParent( ragdoll ) -- So their player ent will match up (position-wise) with where their ragdoll is.
			-- Set velocity for each piece of the ragdoll
			local j = 1
			while true do -- Break inside
				local phys_obj = ragdoll:GetPhysicsObjectNum( j )
				if phys_obj then
					phys_obj:SetVelocity( velocity )
					j = j + 1
				else
					break
				end
			end

			v:Spectate( OBS_MODE_CHASE )
			v:SpectateEntity( ragdoll )
			v:StripWeapons() -- Otherwise they can still use the weapons.


			v.ragdoll = ragdoll
		end
	end
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			if not v.ragdoll:IsValid() then -- Something must have removed it, just spawn
				SpawnPlayer(v)
			else
				local pos = v.ragdoll:GetPos()
				pos.z = pos.z + 10 -- So they don't end up in the ground

				SpawnPlayer(v)
				v:SetPos( pos )
				v:SetVelocity( v.ragdoll:GetVelocity() )
				local yaw = v.ragdoll:GetAngles().yaw
				v:SetAngles( Angle( 0, yaw, 0 ) )
				v.ragdoll:Remove()
			end
		end
	end)
end

local function SpeedTime()
	print("speeding up time!")
	SendTimer(true, nil, GetActionDuration() * 2)
	game.SetTimeScale(2)
	hook.Add("EntityEmitSound", "PitchUpSounds", function(tab)
		local p = tab.Pitch
		p = p * 2
		tab.Pitch = math.Clamp( p, 0, 255 )
		return true
	end)
	timer.Simple(GetActionDuration() * 2, function()
		game.SetTimeScale(1)
		hook.Remove("EntityEmitSound", "PitchUpSounds")
	end)
end

local function SlowTime()
	print("slowing time!")
	SendTimer(true, nil, GetActionDuration() / 2)
	game.SetTimeScale(0.5)
	hook.Add("EntityEmitSound", "PitchDownSounds", function(tab)
		local p = tab.Pitch
		p = p * 0.5
		tab.Pitch = math.Clamp( p, 0, 255 )
		return true
	end)
	timer.Simple(GetActionDuration() / 2, function()
		game.SetTimeScale(1)
		hook.Remove("EntityEmitSound", "PitchDownSounds")
	end)
end

local function SpeedUp()
	print("speeding up!")
	SendTimer(false, GetAlivePlayers())
	speedup = true
	timer.Simple(GetActionDuration(), function()
		speedup = false
	end)
end

local function SlowDown()
	print("slowing down!")
	SendTimer(false, GetAlivePlayers())
	slowdown = true
	timer.Simple(GetActionDuration(), function()
		slowdown = false
	end)
end

local function ReverseControls()
	print("reversing controls")
	SendTimer(false, GetAlivePlayers())
	net.Start("ReverseControls")
	net.Send(GetAlivePlayers())
end

function ApplyAccel( ent, magnitude, direction, dTime ) // Ulib
	if dTime == nil then dTime = 1 end

	if magnitude ~= nil then
		direction:Normalize()
	else
		magnitude = 1
	end

	-- Times it by the time elapsed since the last update.
	local accel = magnitude * dTime
	-- Convert our scalar accel to a vector accel
	accel = direction * accel

	if ent:GetMoveType() == MOVETYPE_VPHYSICS then
		-- a = f/m , so times by mass to get the force.
		local force = accel * ent:GetPhysicsObject():GetMass()
		ent:GetPhysicsObject():ApplyForceCenter( force )
	else
		ent:SetVelocity( accel ) -- As it turns out, SetVelocity() is actually SetAccel() in GM10
	end
end

local function MegaSlap() // also from Ulib
	print("mega slap time")
	local plys = GetAlivePlayers()
	isSlapping = true
	for k, v in ipairs(plys) do
		if v:GetMoveType() == MOVETYPE_OBSERVER then return end
		power = 750

		if v:IsPlayer() then
			if not v:Alive() then
				return
			end

			if v:InVehicle() then
				v:ExitVehicle()
			end

			if v:GetMoveType() == MOVETYPE_NOCLIP then
				v:SetMoveType( MOVETYPE_WALK )
			end
		end

		local direction = Vector( math.random( 20 )-5, math.random( 20 )-5, math.random(10, 20))
		ApplyAccel( v, power, direction )

		local angle_punch_pitch = math.Rand( -20, 20 )
		local angle_punch_yaw = math.sqrt( 20*20 - angle_punch_pitch * angle_punch_pitch )
		if math.random( 0, 1 ) == 1 then
			angle_punch_yaw = angle_punch_yaw * -1
		end
		v:ViewPunch( Angle( angle_punch_pitch, angle_punch_yaw, 0 ) )
	end
	timer.Simple(5, function()
		isSlapping = false
	end)
end

local function FloorIsIce()
	print("the floor is ice!")
	SendTimer(true)
	RunConsoleCommand("sv_friction", -0.01)
	timer.Simple(GetActionDuration(), function()
		RunConsoleCommand("sv_friction", 8)
	end)
end

local function SilentHill()
	print("silent hill...")
	SendTimer(true)
	net.Start("SilentHill")
	net.Broadcast()
end

local function SwapPositions()
	print("swap positions")
	local plys = GetAlivePlayers()
	local plyPositions = {}
	for k, v in ipairs(plys) do
		table.insert(plyPositions, v:GetPos())
	end
	for k, v in ipairs(plys) do
		if #plyPositions >= 2 then
			if k % 2 == 0 then
				v:SetPos(plyPositions[k - 1])
			else
				if not plyPositions[k + 1] then continue end
				v:SetPos(plyPositions[k + 1])
			end
		end
	end
end

local function TimeSkip()
	print("time has been skipped!")
	for k, v in ipairs(player.GetAll()) do
		if not TimeSkipTab[k].eyeangles or not TimeSkipTab[k].pos then continue end
		if not v:Alive() and TimeSkipTab[k].wasAlive then SpawnPlayer(v) end
		timer.Simple(0.1, function() v:SetPos(TimeSkipTab[k].pos) v:SetEyeAngles(TimeSkipTab[k].eyeangles) end)
	end
end

local function UpsideDownCameras()
	print("the cameras are upside down!")
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	for k, v in ipairs(plys) do
		local plyAngles = v:EyeAngles()
		v:SetEyeAngles(Angle(plyAngles.pitch, plyAngles.yaw, 180))
	end
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			local angs = v:EyeAngles()
			v:SetEyeAngles(Angle(angs.pitch, angs.yaw, 0))
		end
	end)
end

local function Bomberman()
	print("bomberman!")
	for k, v in ipairs(player.GetAll()) do
		local barrel = ents.Create("prop_physics")
		if IsValid(barrel) then
			print(barrel:Health())
			barrel:SetModel("models/props_c17/oildrum001_explosive.mdl")
			barrel:SetPos(v:GetPos())
			barrel:SetCollisionGroup(COLLISION_GROUP_WORLD)
			barrel:Spawn()
			timer.Simple(1, function() barrel:Ignite(5) end)
			//print(constraint.NoCollide(v, barrel, 0, 0))
		end
	end
end

local function AntFight()
	print("ant fight!")
	SendTimer(true)
	hook.Run("AntFight", 0.3)
	net.Start("AntFight")
		net.WriteFloat(0.3)
	net.Broadcast()
	timer.Simple(GetActionDuration(), function()
		net.Start("AntFight")
			net.WriteFloat(1)
		net.Broadcast()
		hook.Run("AntFight", 1)
	end)
end

local function BigHeadMode() // can be laggy if lots of players
	print("ya got a big head")
	local plys = GetAlivePlayers()
	SendTimer(true)
	for k, v in ipairs(plys) do
		local bone = v:LookupBone("ValveBiped.Bip01_Head1")
		if bone then
			v:ManipulateBoneScale(bone, Vector(10, 10, 10))
		end
	end
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			local bone = v:LookupBone("ValveBiped.Bip01_Head1")
			if bone then
				v:ManipulateBoneScale(bone, Vector(1, 1, 1))
			end
		end
	end)
end

local function JellyMode()
	print("jelly mode")
	SendTimer(true)
	local plys = GetAlivePlayers()
	for k, v in ipairs(plys) do
		local i = 0

		while i < v:GetBoneCount() do
			v:ManipulateBoneJiggle( i, 1 )
			i = i + 1
		end
	end
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			local i = 0

			while i < v:GetBoneCount() do
				v:ManipulateBoneJiggle( i, 0 )
				i = i + 1
			end
		end
	end)
end

local function Paranoia()
	print("darkness...")
	ParanoiaVar = true
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	for k, ply in ipairs(plys) do -- from ulib https://github.com/TeamUlysses/ulib/blob/master/LICENSE.md -- changes were made 
		local visibility = 0
		ply:DrawShadow( false )
		ply:SetMaterial( "models/effects/vol_light001" )
		ply:SetRenderMode( RENDERMODE_TRANSALPHA )
		ply:Fire( "alpha", visibility, 0 )
		ply:GetTable().invis = { vis=visibility, wep=ply:GetActiveWeapon() }

		if IsValid( ply:GetActiveWeapon() ) then
			ply:GetActiveWeapon():SetRenderMode( RENDERMODE_TRANSALPHA )
			ply:GetActiveWeapon():Fire( "alpha", visibility, 0 )
			ply:GetActiveWeapon():SetMaterial( "models/effects/vol_light001" )
			if ply:GetActiveWeapon():GetClass() == "gmod_tool" then
				ply:DrawWorldModel( false ) -- tool gun has problems
			else
				ply:DrawWorldModel( true )
			end
		end
	end
	net.Start("Paranoia")
	net.Broadcast()
	timer.Simple(GetActionDuration(), function()
		ParanoiaVar = false
		for k, ply in ipairs(plys) do
			ply:DrawShadow( true )
			ply:SetMaterial( "" )
			ply:SetRenderMode( RENDERMODE_NORMAL )
			ply:Fire( "alpha", 255, 0 )
			local activeWeapon = ply:GetActiveWeapon()
			if IsValid( activeWeapon ) then
				activeWeapon:SetRenderMode( RENDERMODE_NORMAL )
				activeWeapon:Fire( "alpha", 255, 0 )
				activeWeapon:SetMaterial( "" )
			end
			ply:GetTable().invis = nil
		end
	end)
end

local function Blindness()
	print("blindness")
	SendTimer(false, GetAlivePlayers())
	for k, v in ipairs(GetAlivePlayers()) do
		v:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0), 3, GetActionDuration() - 1)
	end
end

local function Deafness()
	print("deafness")
	DeafnessVar = true
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	for k, v in ipairs(plys) do
		v:SetDSP(31, false)
	end
	hook.Add("EntityEmitSound", "Deafness", function()
		return false
	end)
	timer.Simple(GetActionDuration(), function()
		DeafnessVar = false
		for k, v in ipairs(plys) do
			v:SetDSP(1, false)
		end
		hook.Remove("EntityEmitSound", "Deafness")
	end)
end

local function Tinnitus()
	print("eeeee tinnitus eeeeee")
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	timer.Create("Tinnitus", 1, 14, function()
		for k, v in ipairs(plys) do
			v:SetDSP(35, false)
		end
	end)
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			v:SetDSP(1, false)
		end
	end)
end

local function BouncyJump()
	print("bouncy time")
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	bouncyJump = true
	for k, v in ipairs(plys) do
		v:SetJumpPower(600)
	end
	timer.Simple(GetActionDuration(), function()
		bouncyJump = false
		for k, v in ipairs(plys) do
			v:SetJumpPower(200)
		end
	end)
end

local function BackseatGaming()
	// OK SO... i wanted it to be like one person controls the camera and one controls the movement but idk how that could work...
end

local function ThirdPerson()
	local aliveplys = GetAlivePlayers()
	SendTimer(false, aliveplys)
	net.Start("Thirdperson")
	net.Send(aliveplys)
end

local function CreateFrag(ply)
	local grenade = ents.Create("npc_grenade_frag")
	if IsValid(grenade) then
		local plypos = ply:GetPos()
		grenade:SetPos(plypos + Vector(0, 0, 100))
		grenade:Spawn()
		grenade:Fire("SetTimer", 3, 0)
		//grenade:Fire("SetHealth", 9999, 0)
		grenade:SetHealth(9999)
	end
end

local function RainingBombs()
	// i want to rain HL2 grenades over the map to keep players moving, maybe even over their heads
	SendTimer(true)
	local SpecialFunc = false
	if GetGlobalInt("ActionCounter") % 10 == 0 then PrintMessage(HUD_PRINTTALK, "Double Bombs!") SpecialFunc = true end
	timer.Create("RainingBombs", 1.5, GetActionDuration(), function()
		for k, v in ipairs(player.GetAll()) do
			CreateFrag(v)
			if SpecialFunc then
				CreateFrag(v)
			end
		end
	end)
end

local function newCrab(pos, ang, ply, b) // ulib again
	local typeofcrab = math.random(3)
	local crabtab = {
		[1] = "npc_headcrab",
		[2] = "npc_headcrab_fast",
		[3] = "npc_headcrab_poison"
	}
	local ent = ents.Create( crabtab[typeofcrab] )
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()
	ent:AddRelationship("player D_HT 98") 
	ent:AddEntityRelationship( ply, D_HT, 99 ) -- Hate target

	return ent
end

local function CrabInfestation()
	print("spawning crabs")
	local plys = GetAlivePlayers()
	for i=1, #plys do
		local v = plys[i]

		local pos = {}
		local currentcrabs = 0
		local testent = newCrab( Vector( 0, 0, 0 ), Angle( 0, 0, 0 ), v, true ) -- Test ent for traces

		local yawForward = v:EyeAngles().yaw
		local directions = {
			math.NormalizeAngle( yawForward - 180 ), -- Behind first
			math.NormalizeAngle( yawForward + 90 ), -- Right
			math.NormalizeAngle( yawForward - 90 ), -- Left
			yawForward,
		}

		local t = {}
		t.start = v:GetPos() + Vector( 0, 0, 64 ) -- Move them up a bit so they can travel across the ground
		t.filter = { v, testent }

		for i=1, #directions do
			t.endpos = v:GetPos() + Angle( 0, directions[i], 0 ):Forward() * 47 -- (33 is player width, this is sqrt( 33^2 * 2 ))
			local tr = util.TraceEntity( t, testent )

			if not tr.Hit then
				table.insert( pos, v:GetPos() + Angle( 0, directions[i], 0 ):Forward() * 47 )
			end
		end

		testent:Remove() -- Don't forget to remove our friend now!

		if #pos > 0 then
			for _, newpos in ipairs( pos ) do
				if currentcrabs >= 3 then continue end
				local newang = (v:GetPos() - newpos):Angle()

				local ent = newCrab( newpos, newang, v )
				currentcrabs = currentcrabs + 1
			end
		else
			v:ChatPrint("Cannot find suitable location to spawn crab.")
		end
	end
end

local function WhosWho()
	//idea: like cods' who's who (sound clip) where you try to find your body within 15-45 seconds and if not you die
	net.Start("StartTimer")
		net.WriteFloat(GetActionDuration() * 2)
	net.Broadcast()
	local plys = GetAlivePlayers()
	for k, v in ipairs(plys) do
		local plypos = v:GetPos()
		local plymodel = v:GetModel()
		GetPlayerInfoTGM(v)
		v:Spawn()
		v:StripWeapons()
		v.WhosWho = true
		local whoswhoent = ents.Create("tgm_whoswho")
		if IsValid(whoswhoent) then
			whoswhoent:SetPos(plypos)
			whoswhoent:Spawn()
			whoswhoent:Activate()
			whoswhoent:SetPlyName(v:Nick())
			whoswhoent:SetModel(plymodel)
			v.WhosWhoEnt = whoswhoent
		end
	end
	net.Start("WhosWho")
		net.WriteBool(true)
	net.Send(plys)
	timer.Simple(GetActionDuration() * 2, function()
		local affected_plys = {}
		for k, v in ipairs(plys) do
			if v.WhosWho then
				v.WhosWho = false
				v.WhosWhoEnt:Remove()
				v:Kill()
				affected_plys[k] = v
			end
		end
		net.Start("WhosWho")
			net.WriteBool(false)
		net.Send(affected_plys)
	end)
end

local function ItsAMystery()
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("ItsAMystery")
	net.Send(plys)
	for k, v in ipairs(plys) do
		v:EmitSound("itsamystery.mp3", 90, 100, 0.5, CHAN_AUTO)
	end
end

local function Earthquake()
	util.ScreenShake(Vector(0, 0, 0), 30, 30, GetActionDuration(), 999999, true)
end

local function Instakill()
	// cods instakill
	InstakillVar = true
	SendTimer(true)
	net.Start("Instakill")
	net.Broadcast()
	timer.Simple(GetActionDuration(), function()
		InstakillVar = false
	end)
end

local function Kamikaze()
	// one person is chosen as kamikaze, 15 seconds to blow someone up, must blow 3 people up to revive
	KamikazeVar = true
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	math.randomseed(os.time())
	local kamikazeplayer
	if _gamemode == "terrortown" then
		local randplayer = math.random(#plys)
		for k, v in RandomPairs(plys) do
			if v:IsActiveTraitor() or v:IsActiveDetective() then
				kamikazeplayer = v
				break
			end
		end
	else
		kamikazeplayer = plys[math.random(#plys)]
	end
	if DebugMode then kamikazeplayer = plys[1] end
	if not kamikazeplayer:Alive() then print("kamikaze is dead, rerunning") Kamikaze() end // failsafe
	kamikazeplayer:SetHealth(100)
	GetPlayerInfoTGM(kamikazeplayer)
	kamikazeplayer:StripWeapons()
	KamikazePlayer = kamikazeplayer
	kamikazeplayer.Kamikaze = true

	if GetGlobalInt("ActionCounter") % 5 == 0 then
		kamikazeplayer:EmitSound("mario_screaming")
	else
		kamikazeplayer:EmitSound("kamikaze_scream")
	end

	local marker = ents.Create("tgm_kamikazemarker")
	if IsValid(marker) then
		marker:SetPos(kamikazeplayer:GetPos() + Vector(0, 0, 16))
		marker:SetParent(kamikazeplayer)
		marker:Spawn()
	end
	KamikazeMarker = marker

	local id = kamikazeplayer:UserID()
	net.Start("Kamikaze")
		net.WriteUInt(id, 8)
	net.Broadcast()

	timer.Create("KamikazeExplode", GetActionDuration(), 1, function()
		if kamikazeplayer:Alive() then
			local alivePlayers = #GetAlivePlayers() - 1

			local explode = ents.Create("env_explosion")
			if IsValid(explode) then
				explode:SetPos(kamikazeplayer:GetPos())
				explode:SetOwner(kamikazeplayer)
				explode:SetKeyValue("iMagnitude", "250")
				explode:SetKeyValue("spawnflags", "144")
				explode:Spawn()
				explode:Fire("Explode", 0, 0)
				explode:EmitSound("weapon_AWP.Single")
			end

			timer.Simple(0.1, function()
				local alivePlayers2 = #GetAlivePlayers()
				if alivePlayers - alivePlayers2 >= #plys / 5 then
					print(kamikazeplayer:Nick() .. " has succeeded and will be respawned!")
					SpawnPlayer(kamikazeplayer)
				end
			end)
		end

		HandleKamikazeDeath(kamikazeplayer, marker)
	end)
end

local function MobaMode()
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("MobaMode")
	net.Send(plys)
end

local function ReviveEveryone()
	for k, v in ipairs(player.GetAll()) do
		if not v:Alive() then
			if _gamemode == "terrortown" then
				v:SpawnForRound(true)
			else
				v:Spawn()
			end
		end
	end
end

local function BossMode()
	// one person is chosen as The Boss, in TTT they would be the only Traitor in a game of Innocents
	// the damage done to the boss should scale with the amount of players, 1 player = 100% damage, 5 = 20%
	if #GetBossPlayers() == 0 then
		net.Start("BossMode")
			net.WriteBool(true)
		net.Broadcast()
	else
		print("Not starting BossMode netmessage,  players: ", #GetBossPlayers())
	end
	local plys = GetAlivePlayers()
	local boss = plys[GetPseudoRandomNumber(#plys)]
	if DebugMode then boss = plys[1] end
	if boss.IsBoss and not DebugMode then BossMode() return end
	boss.IsBoss = true
	net.Start("BossPlayer")
		net.WriteBool(true)
	net.Send(boss)
	if _gamemode == "terrortown" then
		local _innocent = 0
		local _traitor = 1
		boss:SetRole(_traitor)
		for k, v in ipairs(plys) do
			if v == boss or v.IsBoss then
				boss:SetRole(_traitor)
			else
				v:SetRole(_innocent)
			end
		end
		SendFullStateUpdate()
		boss:StripAll()
		boss:StripWeapons()
		boss:Give("tgm_bossminigun_ttt")

		hook.Add("TTTEndRound", "BossMode_TTTEnd"..boss:Nick(), function(result)
			if result == WIN_TRAITOR then
				print("boss success")
				boss.IsBoss = false
				PrintMessage(HUD_PRINTTALK, boss:Nick() .. " was successful!")
				net.Start("BossMode")
					net.WriteBool(false)
				net.Broadcast()
				net.Start("BossPlayer")
					net.WriteBool(false)
				net.Send(boss)
			end
			hook.Remove("TTTEndRound", "BossMode_TTTEnd"..boss:Nick())
		end)
		hook.Add("TTTPrepareRound", "BossMode_TTTStart"..boss:Nick(), function()
			boss.IsBoss = false
			net.Start("BossMode")
				net.WriteBool(false)
			net.Broadcast()
			net.Start("BossPlayer")
				net.WriteBool(false)
			net.Send(boss)
			hook.Remove("BossMode_TTTStart"..boss:Nick())
		end)
		hook.Add("TTTBeginRound", "BossMode_TTTBegin"..boss:Nick(), function()
			boss.IsBoss = false
			net.Start("BossMode")
				net.WriteBool(false)
			net.Broadcast()
			net.Start("BossPlayer")
				net.WriteBool(false)
			net.Send(boss)
			hook.Remove("BossMode_TTTBegin"..boss:Nick())
		end)
	else
		boss:StripWeapons()
		boss:Give("tgm_bossminigun")
	end
	boss:SetHealth(150)
	PrintMessage(HUD_PRINTTALK, boss:Nick() .. " is the Boss! Kill them quickly!")
	print(GetGlobalInt("ActionCounter", 1))
	if GetGlobalInt("ActionCounter", 1) % 10 == 0 then
		PrintMessage(HUD_PRINTTALK, "DOUBLE BOSS!")
		IncrementActionCounter()
		BossMode()
	end
end

local function TankControls()
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("TankControls")
	net.Send(plys)
end

local function RandomSensitivity()
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("RandomSensitivity")
	net.Send(plys)
end

local function RandomOverlay()
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("RandomOverlay")
	net.Send(plys)
end

local function RandomTexturize()
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("RandomTexturize")
	net.Send(plys)
end

local function Nearsightedness()
	// its DOF but spacing is 8 and initial dist is 9
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("Nearsightedness")
	net.Send(plys)
end

local function ThreeDMode()
	// stereoscopy
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("3DMode")
	net.Send(plys)
end

local function MegaBloom()
	// graphics in 2013
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	net.Start("MegaBloom")
	net.Send(plys)
end

local function GoodnightGirl()
	// makes gravity really high, and really low, probably killing everyone instantly. :)
	math.randomseed(os.time())
	goodnightGirl = true
	for k, v in ipairs(GetAlivePlayers()) do
		//v:SetHealth(10)
		timer.Simple(math.Rand(0.05, 0.35), function()
			v:EmitSound("goodnightgirl.mp3", 100, 100, 0.5, CHAN_AUTO)
			timer.Simple(2.3, function()
				RunConsoleCommand("sv_gravity", "0")
				local direction = Vector( 0, 0, math.Rand(1, 1.5) )
				local power = math.random(250, 450)
				v:ViewPunch(Angle(40, 0, 0))
				ApplyAccel( v, power, direction )
				timer.Simple(0.7, function()
					RunConsoleCommand("sv_gravity", "600")
					local direction = Vector( math.Rand(-0.5, 0.5), math.Rand(-0.5, 0.5), -2 )
					local power = math.random(800, 1000)
					v:ViewPunch(Angle(-40, 0, 0))
					ApplyAccel( v, power, direction )
				end)
			end)
		end)
	end
	timer.Simple(5, function()
		goodnightGirl = false
	end)
end

local function PunchScreen()
	SendTimer(true)
	for k, v in ipairs(GetAlivePlayers()) do
		timer.Create("Punch"..v:Nick(), 0.5, GetActionDuration() * 2, function()
			local rand = AngleRand(-10, 10)
			local eyeang = v:EyeAngles()
			eyeang.pitch = eyeang.pitch + rand.pitch
			eyeang.yaw = eyeang.yaw + rand.yaw
			eyeang:Normalize()
			v:ViewPunch(eyeang)
		end)
	end
end

local function MathTime()
	local plys = GetAlivePlayers()
	SendTimer(false, plys)
	// basically it selects a random question or maybe math question (or both) and people have to type the answer in chat or else they die
	local firstvar = math.random(-25, 25)
	local lastvar = math.random(-25, 25)
	local question_string = firstvar .. " + ".. lastvar .. " = ?"
	local answer = firstvar + lastvar
	print(answer)

	PrintMessage(HUD_PRINTTALK, question_string)
	PrintMessage(HUD_PRINTCENTER, question_string)
	timer.Create("PrintQuestion", 1, GetActionDuration() - 1, function()
		PrintMessage(HUD_PRINTCENTER, question_string)
	end)

	hook.Add("PlayerSay", "CheckPlayerAnswer", function(sender, txt, teamchat)
		print(txt)
		if txt == tostring(answer) then
			sender:PrintMessage(HUD_PRINTTALK, "You answered correctly!")
			sender.MathWin = true
			return ""
		end
	end)
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
			if v.MathWin then v.MathWin = false continue end
			v:PrintMessage(HUD_PRINTTALK, "You failed!")
			v:TakeDamage(40, v, v)
		end
	end)
end

local prop_models = {
	[1] = "models/props_borealis/bluebarrel001.mdl",
	[2] = "models/props_c17/FurnitureWashingmachine001a.mdl",
	[3] = "models/props_c17/oildrum001_explosive.mdl",
	[4] = "models/props_c17/oildrum001.mdl",
	[5] = "models/props_junk/watermelon01.mdl",
	[6] = "models/props_c17/doll01.mdl",
	[7] = "models/props_combine/breenbust.mdl"
}

local function PropHunt()
	// every player gets their model set to a random prop
	local plys = GetAlivePlayers()
	local ply_models = {}
	SendTimer(true)
	math.randomseed(os.time())
	for k, v in ipairs(plys) do
		table.insert(ply_models, v:GetModel())
		v:SetModel(prop_models[math.random(#prop_models)])
	end
	timer.Simple(GetActionDuration(), function()
		for k, v in ipairs(plys) do
			v:SetModel(ply_models[k])
		end
	end)
end

local function Phoon()
	SendTimer(true)
	PhoonMode = true
	SetGlobalBool("PhoonMode", true)
	RunConsoleCommand("sv_airaccelerate", "1000")
	RunConsoleCommand("sv_friction", "4")
	RunConsoleCommand("sv_sticktoground", "0")
	RunConsoleCommand("sv_maxvelocity", "9000")
	local jump_powers = {}
	for k, v in ipairs(GetAlivePlayers()) do
		v:ConCommand("+jump")
		table.insert(jump_powers, v:GetJumpPower())
		v:SetJumpPower(284)
		v:SetAvoidPlayers(false)
	end
	hook.Add("OnPlayerHitGround", "PhoonBhop", function(ply, inwater, onfloat, speed)
		ply:ConCommand("+jump")
	end)
	/*hook.Add("HUDPaint", "PaintSpeed", function()
		print("fug")
		draw.SimpleText("Your velocity is: " .. math.floor(tostring(v:GetVelocity():Length())), "DermaLarge", 50, 50)
	end)*/
	timer.Create("PhoonJumpCheck", 0.1, GetActionDuration() * 10, function()
		for k, v in ipairs(GetAlivePlayers()) do
			if not v:IsOnGround() then
				v:ConCommand("-jump")
				v:PrintMessage(HUD_PRINTCENTER, "Your velocity is: " .. math.floor(tostring(v:GetVelocity():Length())))
			end
		end
	end)
	timer.Simple(GetActionDuration(), function()
		SetGlobalBool("PhoonMode", false)
		PhoonMode = false
		hook.Remove("OnPlayerHitGround", "PhoonBhop")
		RunConsoleCommand("sv_airaccelerate", "10")
		RunConsoleCommand("sv_friction", "8")
		RunConsoleCommand("sv_sticktoground", "1")
		RunConsoleCommand("sv_maxvelocity", "3500")
		for k, v in ipairs(player.GetAll()) do
			v:ConCommand("-jump")
			v:SetAvoidPlayers(true)
			if not jump_powers[k] then v:SetJumpPower(jump_powers[1]) continue end
			v:SetJumpPower(jump_powers[k])
		end
	end)
end

local function ChatBoss()
	// so it spawns a chat boss entity, and only chat can defeat it. it is invincible, shooting only moves it back.
	if ChatBossMode then ErrorNoHalt("You can't do two chat bosses!") return end
	if not WEBSOCKET:isConnected() then ErrorNoHalt("Chat boss is not meant for non-streams!") return end
	local boss = ents.Create("tgm_chatboss")
	if boss then
		WEBSOCKET:write("ChatBossStatus;true")
		print("spawned chatboss")
		PrintMessage(HUD_PRINTCENTER, string.format("The Chat Boss lvl.%i has appeared! Type \"!attack\" in chat to defeat it!", GetGlobalInt("ChatBossStreak", 1)))
		boss:Spawn()
		boss:Activate()
		boss:SetCollisionGroup(COLLISION_GROUP_WORLD)
		local maxbosshealth = math.Max( (TGM_CurrentViewers / 10), 5 ) * math.Max(GetGlobalInt("ChatBossStreak", 1), 1)
		boss:SetMaxHealth(maxbosshealth)
		boss:SetHealth(maxbosshealth)
		timer.Simple(0.1, function()
			net.Start("ChatBoss")
				net.WriteBool(true)
				net.WriteEntity(boss)
			net.Broadcast()
		end)
		ChatBossMode = true
		ChatBossEnt = boss
		boss:CallOnRemove("WriteChatbossStatus", function(ent) ChatBossMode = false WEBSOCKET:write("ChatBossStatus;false") end)
	end
end

local function SPBossMode()
	// so the streamer becomes the boss for 30 seconds
	if not TGM_Streamer then ErrorNoHalt("No one is set as the streamer, this action won't work!") return end
	net.Start("BossMode")
		net.WriteBool(true)
	net.Broadcast()
	SendTimer(true, nil, GetActionDuration() * 2)
	local boss = TGM_Streamer
	boss:Give("tgm_bossminigun")
	timer.Simple(GetActionDuration() * 2, function()
		boss:StripWeapon("tgm_bossminigun")
		net.Start("BossMode")
			net.WriteBool(false)
		net.Broadcast()
		timer.Simple(0.1, function() 
			boss:ConCommand("-walk")
			boss:ConCommand("snd_restart") 
		end)
	end)
end

local function ChonkyPlayers()
	SendTimer(true)
	net.Start("TGM_ChonkyPlayers")
		net.WriteInt(7, 6)
	net.Broadcast()
	timer.Simple(GetActionDuration(), function()
		net.Start("TGM_ChonkyPlayers")
			net.WriteInt(1, 6)
		net.Broadcast()
	end)
end

local function UpsidedownPlayers()
	SendTimer(true)
	net.Start("TGM_UpsidedownPlayers")
		net.WriteBool(true)
	net.Broadcast()
	timer.Simple(GetActionDuration(), function()
		net.Start("TGM_UpsidedownPlayers")
			net.WriteBool(false)
		net.Broadcast()
	end)
end

print("setting actions...")
/* UTILITY ACTIONS */
WSFunctions["printtwitchchat"] = {enabled = true, func = PrintTwitchChat}
WSFunctions["votetime"] = {enabled = true, func = VoteTime}
WSFunctions["voteinfo"] = {enabled = true, func = VoteInfo}
/* GAME ACTIONS */
WSFunctions["randomizeviews"] = {enabled = true, func = RandomizeViews}
WSFunctions["lowergravity"] = {enabled = true, func = LowerGravity}
WSFunctions["deepfry"] = {enabled = true, func = DeepFry}
WSFunctions["inception"] = {enabled = true, func = Inception}
WSFunctions["masterfov"] = {enabled = true, func = MasterFOV}
WSFunctions["speedup"] = {enabled = true, func = SpeedUp}
WSFunctions["slowdown"] = {enabled = true, func = SlowDown}
WSFunctions["reversecontrols"] = {enabled = true, func = ReverseControls}
WSFunctions["megaslap"] = {enabled = true, func = MegaSlap}
WSFunctions["floorisice"] = {enabled = true, func = FloorIsIce}
WSFunctions["silenthill"] = {enabled = true, func = SilentHill}
WSFunctions["timeskip"] = {enabled = true, func = TimeSkip}
WSFunctions["upsidedowncams"] = {enabled = true, func = UpsideDownCameras}
WSFunctions["bomberman"] = {enabled = true, func = Bomberman}
WSFunctions["antfight"] = {enabled = true, func = AntFight}
WSFunctions["paranoia"] = {enabled = true, func = Paranoia}
WSFunctions["blindness"] = {enabled = true, func = Blindness}
WSFunctions["deafness"] = {enabled = true, func = Deafness}
WSFunctions["tinnitus"] = {enabled = true, func = Tinnitus}
WSFunctions["bouncyjump"] = {enabled = true, func = BouncyJump}
WSFunctions["thirdperson"] = {enabled = true, func = ThirdPerson}
WSFunctions["crabinfestation"] = {enabled = true, func = CrabInfestation}
WSFunctions["itsamystery"] = {enabled = true, func = ItsAMystery}
WSFunctions["earthquake"] = {enabled = true, func = Earthquake}
WSFunctions["mobamode"] = {enabled = true, func = MobaMode}
WSFunctions["tankcontrols"] = {enabled = true, func = TankControls}
WSFunctions["randomsensitivity"] = {enabled = true, func = RandomSensitivity}
WSFunctions["randomoverlay"] = {enabled = true, func = RandomOverlay}
WSFunctions["randomtexturize"] = {enabled = true, func = RandomTexturize}
WSFunctions["nearsightedness"] = {enabled = true, func = Nearsightedness}
WSFunctions["3dmode"] = {enabled = true, func = ThreeDMode}
WSFunctions["megabloom"] = {enabled = true, func = MegaBloom}
WSFunctions["goodnightgirl"] = {enabled = true, func = GoodnightGirl}
WSFunctions["punchscreen"] = {enabled = true, func = PunchScreen}
WSFunctions["speedtime"] = {enabled = true, func = SpeedTime}
WSFunctions["slowtime"] = {enabled = true, func = SlowTime}
WSFunctions["phoon"] = {enabled = true, func = Phoon}
WSFunctions["spbossmode"] = {enabled = true, func = SPBossMode}
/* MULTIPLAYER-BASED ACTIONS */
WSFunctions["prophunt"] = {enabled = true, func = PropHunt}
WSFunctions["spawnzombies"] = {enabled = true, func = SpawnZombies}
WSFunctions["zawarudo"] = {enabled = true, func = ZaWarudo}
WSFunctions["invisiblewarfare"] = {enabled = true, func = InvisibleWarfare}
if _gamemode != "terrortown" then
	WSFunctions["ragdolleveryone"] = {enabled = true, func = RagdollEveryone} // doesnt work in ttt
end
WSFunctions["swappositions"] = {enabled = true, func = SwapPositions}
WSFunctions["bigheadmode"] = {enabled = true, func = BigHeadMode}
WSFunctions["jellymode"] = {enabled = true, func = JellyMode}
WSFunctions["rainingbombs"] = {enabled = true, func = RainingBombs}
WSFunctions["whoswho"] = {enabled = false, func = WhosWho}
WSFunctions["instakill"] = {enabled = true, func = Instakill}
WSFunctions["kamikaze"] = {enabled = true, func = Kamikaze}
WSFunctions["reviveeveryone"] = {enabled = true, func = ReviveEveryone}
WSFunctions["bossmode"] = {enabled = true, func = BossMode}
WSFunctions["mathtime"] = {enabled = true, func = MathTime}
WSFunctions["chatboss"] = {enabled = false, func = ChatBoss} -- disabled due to a bug with the twitch program i made
WSFunctions["chonkyplayers"] = {enabled = true, func = ChonkyPlayers}
WSFunctions["upsidedownplayers"] = {enabled = true, func = UpsidedownPlayers}

if file.Exists("tgm_actions.txt", "DATA") then
	local data = file.Read("tgm_actions.txt", "DATA")
	data = string.Split(data, "\n")
	for k, v in ipairs(data) do
		local args = string.Split(v, ";")
		if #args != 2 then continue end
		WSFunctions[args[1]].enabled = tobool(args[2]) // time to sleep, will do this tomorrow
		// my best bet might be to make the WSFunctions[key] = {enabled = true, func = PrintTwitchChat} something like that. would be best
	end
end

//WSFunctions["backseatgaming"] = BackseatGaming