WSFunctions = WSFunctions or {}
local votes = {}
local votable_funcs = {}
local voting_time = false
local vote_length = 15
local max_votable_funcs = 2

local isSlapping = false
local speedup = false
local slowdown = false
local oldPlyPos = {}
local oldPlyView = {}
local bouncyJump = false

local ActionDuration = 15

local function RandomizeViews()
	print("randomizing views")
	//net.Start("TimedActionStart") i might do this idk
	//net.Broadcast()
	local plys = player.GetAll()
	local plyAngles = {}
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		plyAngles[k] = v:EyeAngles()
		v:SetEyeAngles(AngleRand())
	end
	timer.Simple(ActionDuration, function()
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
			v:SetEyeAngles(Angle(plyAngles[k].pitch, plyAngles[k].yaw, 0))
		end
	end)
	// set all player viewangles to random vectors
end

local function LowerGravity()
	print("lowering gravity")
	for k, v in pairs(player.GetAll()) do
		v:ChatPrint("Lowering gravity!")
	end
	local oldgrav = physenv.GetGravity() // default grav is Vector(0, 0, -600)
	print(oldgrav)
	local oldnumgrav = GetConVar("sv_gravity"):GetInt()
	RunConsoleCommand("sv_gravity", "200")
	timer.Simple(ActionDuration, function()
		RunConsoleCommand("sv_gravity", oldnumgrav)
	end)
	//physenv.SetGravity(Vector())
	// lower gravity real low
end

local function FuckWithScreen()
	print("fucking up their screens")
	// server to client, fuck up saturation and contrast an shit
	net.Start("FuckWithScreen")
	net.Broadcast()
end

local function Inception()
	print("bwaaam. inception time")
	//local oldnumgrav = GetConVar("sv_gravity"):GetInt()
	// lower gravity below 0 for a period of time, then bring it back to normal
	RunConsoleCommand("sv_gravity", "80")
	RunConsoleCommand("sv_airaccelerate", "1000")
	RunConsoleCommand("sv_sticktoground", "0")
	net.Start("Inception")
	net.Broadcast()
	for k, v in ipairs(player.GetAll()) do
		if not v:Alive() then continue end
		local power = 100
		local direction = Vector( math.random( 5 )-10, math.random( 5 )-10, math.random( 5 ) )
		if not v:Alive() then
			return
		end
		local accel = power
		accel = direction * accel
		v:SetVelocity( accel )
	end
	timer.Simple(ActionDuration, function()
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
	local plys = player.GetAll()
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
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
			print("cant find suitable place for zombie, you're safe")
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
	local plys = player.GetAll()
	local plyFovs = {}
	for k, v in pairs(plys) do
		if not v:Alive() then continue end
		plyFovs[k] = v:GetFOV()
		v:SetFOV(177, 1)
		v:ChatPrint("MASTER FOV ENGAGED")
	end
	timer.Simple(ActionDuration, function()
		for k, v in pairs(plys) do
			v:SetFOV(plyFovs[k], 1)
		end
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
		local func, key = table.Random(WSFunctions)

		if key == "printtwitchchat" or key == "voteinfo" or key == "votetime" then
			continue
		end

		if tab.isDouble then  // if it is a double vote
			local func2, key2 = table.Random(WSFunctions)

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

local function VoteTime(isDoubleVote)
	if not isDoubleVote then isDoubleVote = false end
	if not voting_time then
		WEBSOCKET:write("VoteTime")
		print("voting time!")
		hook.Run("VotingStarted")

		voting_time = true
		math.randomseed(os.time())
		GetVotableFuncs(votable_funcs, isDoubleVote)
		PrintTable(votable_funcs)

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

		timer.Create("UpdateMenu", vote_length / 30, 30 - 1, function()
			local json = util.TableToJSON(votable_funcs)
			local data = util.Compress(json)
			net.Start("UpdateDerma")
				net.WriteUInt(#data, 16)
				net.WriteData(data, #data)
			net.Broadcast()
		end)
		// open a derma menu on clientside and send json of the votes
		timer.Simple(vote_length, function()
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
				WSFunctions[winning_func]()
				WSFunctions[winning_func2]()
			else
				print(winning_func)
				PrintMessage(HUD_PRINTTALK, PrettyFuncs[winning_func])
				WSFunctions[winning_func]()
			end
			
			table.Empty(votable_funcs)
			voting_time = false

			net.Start("EndVoting")
			net.Broadcast()
		end)
	end
end

local function ContainsFunc(tab, func)
	for k, v in pairs(tab) do
		if v.name == func then
			//print(v.name .. " = " .. func)
			return true
		else
			//print(v.name .. " != " .. func)
			continue
		end
	end
	return false
end

local function GetKey(tab, func)
	for k, v in pairs(tab) do
		if v.name == func then
			return k
		end
	end
end

local function VoteInfo(user, message)
	print("info received")
	if not ContainsFunc(votable_funcs, message) then return end
	local key = GetKey(votable_funcs, message)
	votable_funcs[key].value = votable_funcs[key].value + 1
	PrintTable(votable_funcs)
end

local function ZaWarudo() // from Vipes, edited for personal use https://steamcommunity.com/id/lordvipes
	print("ZA WARUDO")
	local plys = player.GetAll()
	// look at the addon
	net.Start("the_world_time_stop.PlaySound")
	net.Broadcast()
	timer.Create("TheWorld", 2, 1, function()
		RunConsoleCommand( "phys_timescale", "0" )
		RunConsoleCommand( "ai_disabled", "1" )
		RunConsoleCommand( "ragdoll_sleepaftertime", "0" )
		math.randomseed(os.time())
		local randplayer = math.random(#plys)
		for k, v in pairs(plys) do
			if v:Alive() and k != randplayer then
				v:Freeze( true )
				v:SetMoveType(MOVETYPE_NOCLIP)
				v:ScreenFade( SCREENFADE.OUT, Color(0, 0, 0), 1, ActionDuration - 1) // this should be cool than just a screenfade
			end
		end
		timer.Create("stoppedTime", ActionDuration - 1, 1, function()
			net.Start("the_world_time_start.PlaySound")
			net.Broadcast()
			timer.Create("StartTime", 1, 1, function()
				RunConsoleCommand( "phys_timescale", "1" )
				RunConsoleCommand( "ai_disabled", "0" )
				RunConsoleCommand( "ragdoll_sleepaftertime", "5" )
				for k, v in pairs(plys) do
					if v:Alive() and k != randplayer then
						v:Freeze( false )
						v:SetMoveType(MOVETYPE_WALK)
					end
				end
			end)
		end)
	end)
end

local function InvisibleWarfare()
	print("making everyone invisible!")
	local plys = player.GetAll()
	net.Start("PlayCloakSound")
		net.WriteBool(true)
	net.Broadcast()
	for k, ply in ipairs(plys) do // from ulib https://github.com/TeamUlysses/ulib/blob/master/LICENSE.md -- changes were made 
		if not ply:Alive() then continue end
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
	timer.Simple(ActionDuration, function()
		net.Start("PlayCloakSound")
			net.WriteBool(false)
		net.Broadcast()
		for k, ply in ipairs(plys) do
			if not ply:Alive() then continue end
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

local function GetPlayerInfoTGM(player)
	local result = {}

	local t = {} // also from ulib
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

local function doWeapons( player, t )
	if not player:IsValid() then return end // also from Ulib

	player:StripAmmo()
	player:StripWeapons()

	for printname, data in pairs( t.data ) do
		player:Give( printname )
		local weapon = player:GetWeapon( printname )
		weapon:SetClip1( data.clip1 )
		weapon:SetClip2( data.clip2 )
		player:SetAmmo( data.ammo1, weapon:GetPrimaryAmmoType() )
		player:SetAmmo( data.ammo2, weapon:GetSecondaryAmmoType() )
	end

	if t.curweapon then
		player:SelectWeapon( t.curweapon )
	end
end

local function SpawnPlayer(player)
	player:Spawn()

	if player.SpawnInfo then
		local t = player.SpawnInfo
		player:SetHealth( t.health )
		player:SetArmor( t.armor )
		timer.Simple( 0.1, function() doWeapons( player, t ) end )
		player.SpawnInfo = nil
	end
end

local function RagdollEveryone()
	print("ragdolling everyone!")
	local plys = player.GetAll()
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
	timer.Simple(ActionDuration, function()
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
	RunConsoleCommand("host_timescale", "2")
	timer.Simple(ActionDuration, function()
		RunConsoleCommand("host_timescale", "1")
	end)
end

local function SlowTime()
	print("slowing time!")
	RunConsoleCommand("host_timescale", "0.5")
	timer.Simple(ActionDuration, function()
		RunConsoleCommand("host_timescale", "1")
	end)
end

hook.Add("Move", "Speedup or Slowdown", function(ply, mv)
	if speedup then
		local speed = mv:GetMaxSpeed() * 2
		mv:SetMaxSpeed(speed)
		mv:SetMaxClientSpeed(speed)
	elseif slowdown then
		local speed = mv:GetMaxSpeed() / 2
		mv:SetMaxSpeed(speed)
		mv:SetMaxClientSpeed(speed)
	end
end)

local function SpeedUp()
	print("speeding up!")
	speedup = true
	timer.Simple(ActionDuration, function()
		speedup = false
	end)
end

local function SlowDown()
	print("slowing down!")
	slowdown = true
	local plys = player.GetAll()
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		v:SetWalkSpeed(50)
		v:SetRunSpeed(125)
	end	
	timer.Simple(ActionDuration, function()
		slowdown = false
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
			v:SetWalkSpeed(250)
			v:SetRunSpeed(500)
		end
	end)
end

local function ReverseControls()
	print("reversing controls")
	net.Start("ReverseControls")
	net.Broadcast()	
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

hook.Add("GetFallDamage", "SlapOverwrite", function(ply, speed)
	if isSlapping or bouncyJump then
		return 0
	end
end)

local function MegaSlap() // also from Ulib
	print("mega slap time")
	local plys = player.GetAll()
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

		local direction = Vector( math.random( 20 )-5, math.random( 20 )-5, math.random( 20 ) ) -- Make it random, slightly biased to go up.
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
	RunConsoleCommand("sv_friction", -0.01)
	timer.Simple(ActionDuration, function()
		RunConsoleCommand("sv_friction", 8)
	end)
end

local function SilentHill()
	print("silent hill...")
	net.Start("SilentHill")
	net.Broadcast()
end

local function SwapPositions()
	print("swap positions")
	local plys = player.GetAll()
	local plyPositions = {}
	for k, v in ipairs(plys) do
		table.insert(plyPositions, v:GetPos())
	end
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		if #plyPositions >= 2 then
			if k % 2 == 0 then
				v:SetPos(plyPositions[k - 1])
			else
				v:SetPos(plyPositions[k + 1])
			end
		end
	end
end

hook.Add("VotingStarted", "TimeSkipRec", function()
	table.Empty(oldPlyPos)
	table.Empty(oldPlyView)
	for k, v in ipairs(player.GetAll()) do
		table.insert(oldPlyPos, v:GetPos())
		table.insert(oldPlyView, v:EyeAngles())
	end
end)

local function TimeSkip()
	print("time has been skipped!")
	for k, v in ipairs(player.GetAll()) do
		if not v:Alive() then continue end
		if not oldPlyPos[k] then continue end
		if not oldPlyView[k] then continue end
		v:SetPos(oldPlyPos[k])
		v:SetEyeAngles(oldPlyView[k])
	end
end

local function UpsideDownCameras()
	print("the cameras are upside down!")
	local plys = player.GetAll()
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		local plyAngles = v:EyeAngles()
		v:SetEyeAngles(Angle(plyAngles.pitch, plyAngles.yaw, 180))
	end
	timer.Simple(ActionDuration, function()
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
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
			barrel:SetModel("models/props_c17/oildrum001_explosive.mdl")
			barrel:SetPos(v:GetPos())
			barrel:SetCollisionGroup(COLLISION_GROUP_WORLD)
			barrel:Spawn()
			barrel:Ignite(5)
			//print(constraint.NoCollide(v, barrel, 0, 0))
		end
	end
end

local function AntFight()
	print("ant fight!")
	hook.Run("AntFight", 0.3)
	net.Start("AntFight")
		net.WriteFloat(0.3)
	net.Broadcast()
	timer.Simple(ActionDuration, function()
		net.Start("AntFight")
			net.WriteFloat(1)
		net.Broadcast()
		hook.Run("AntFight", 1)
	end)
end

local function BigHeadMode() // can be laggy if lots of players
	print("ya got a big head")
	local plys = player.GetAll()
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		local bone = v:LookupBone("ValveBiped.Bip01_Head1")
		if bone then
			v:ManipulateBoneScale(bone, Vector(10, 10, 10))
		end
	end
	timer.Simple(ActionDuration, function()
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
			local bone = v:LookupBone("ValveBiped.Bip01_Head1")
			if bone then
				v:ManipulateBoneScale(bone, Vector(1, 1, 1))
			end
		end
	end)
end

local function JellyMode()
	print("jelly mode")
	local plys = player.GetAll()
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		local i = 0

		while i < v:GetBoneCount() do
			v:ManipulateBoneJiggle( i, 1 )
			i = i + 1
		end
	end
	timer.Simple(ActionDuration, function()
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
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
	local plys = player.GetAll()
	for k, ply in ipairs(plys) do // from ulib https://github.com/TeamUlysses/ulib/blob/master/LICENSE.md -- changes were made 
		if not ply:Alive() then continue end
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
	timer.Simple(ActionDuration, function()
		for k, ply in ipairs(plys) do
			if not ply:Alive() then continue end
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
	for k, v in ipairs(player.GetAll()) do
		if not v:Alive() then continue end
		v:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0), 1, ActionDuration - 1)
	end
end

local function Deafness()
	print("deafness")
	local plys = player.GetAll()
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		v:SetDSP(31, false)
	end
	timer.Simple(ActionDuration, function()
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
			v:SetDSP(0, false)
		end
	end)
end

local function BouncyJump()
	print("bouncy time")
	local plys = player.GetAll()
	bouncyJump = true
	for k, v in ipairs(plys) do
		if not v:Alive() then continue end
		v:SetJumpPower(600)
	end
	timer.Simple(ActionDuration, function()
		bouncyJump = false
		for k, v in ipairs(plys) do
			if not v:Alive() then continue end
			v:SetJumpPower(200)
		end
	end)
end

local function BackseatGaming()
	// OK SO... i wanted it to be like one person controls the camera and one controls the movement but idk how that could work...
end

local function ThirdPerson()
	local aliveplys = {}
	for k, v in ipairs(player.GetAll()) do
		table.insert(aliveplys, v)
	end
	net.Start("Thirdperson")
		net.WriteBool(true)
	net.Send(aliveplys)
	timer.Simple(ActionDuration, function()
		net.Start("Thirdperson")
			net.WriteBool(false)
		net.Send(aliveplys)
	end)
end

/* UTILITY ACTIONS */
WSFunctions["printtwitchchat"] = PrintTwitchChat
WSFunctions["votetime"] = VoteTime
WSFunctions["voteinfo"] = VoteInfo
/* GAME ACTIONS */
WSFunctions["randomizeviews"] = RandomizeViews
WSFunctions["lowergravity"] = LowerGravity
WSFunctions["fuckwithscreen"] = FuckWithScreen
WSFunctions["inception"] = Inception
WSFunctions["spawnzombies"] = SpawnZombies
WSFunctions["masterfov"] = MasterFOV
WSFunctions["zawarudo"] = ZaWarudo
WSFunctions["invisiblewarfare"] = InvisibleWarfare
WSFunctions["ragdolleveryone"] = RagdollEveryone // doesnt work in ttt
WSFunctions["speedup"] = SpeedUp
WSFunctions["slowdown"] = SlowDown
WSFunctions["reversecontrols"] = ReverseControls
WSFunctions["megaslap"] = MegaSlap
WSFunctions["floorisice"] = FloorIsIce
WSFunctions["silenthill"] = SilentHill
WSFunctions["swappositions"] = SwapPositions
WSFunctions["timeskip"] = TimeSkip
WSFunctions["upsidedowncams"] = UpsideDownCameras
WSFunctions["bomberman"] = Bomberman
WSFunctions["antfight"] = AntFight
WSFunctions["bigheadmode"] = BigHeadMode
WSFunctions["jellymode"] = JellyMode
WSFunctions["paranoia"] = Paranoia
WSFunctions["blindness"] = Blindness
WSFunctions["deafness"] = Deafness
WSFunctions["bouncyjump"] = BouncyJump
WSFunctions["thirdperson"] = ThirdPerson
//WSFunctions["backseatgaming"] = BackseatGaming
//WSFunctions["speedtime"] = SpeedTime
//WSFunctions["slowtime"] = SlowTime DOES NOT WORK WITHOUT SV_CHEATS