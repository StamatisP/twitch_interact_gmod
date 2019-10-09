print("shared file")
local controlsReversed = false
local TankControls = false
local RandomSensitivity = false

ActionDuration = 15 // CHANGE THIS IN ACTIONS TOO

do
	for k, v in pairs(file.Find("sound/*", "THIRDPARTY")) do
		util.PrecacheSound(v)
	end
end

local _models = {
	[1] = "models/props_borealis/bluebarrel001.mdl",
	[2] = "models/props_c17/FurnitureWashingmachine001a.mdl",
	[3] = "models/props_c17/oildrum001_explosive.mdl",
	[4] = "models/props_c17/oildrum001.mdl",
	[5] = "models/props_junk/watermelon01.mdl",
	[6] = "models/props_c17/doll01.mdl",
	[7] = "models/props_combine/breenbust.mdl",
	[8] = "models/zombie/classic.mdl",
	[9] = "models/headcrab.mdl",
	[10] = "models/headcrabblack.mdl"
}

do
	for k, v in ipairs(_models) do
		util.PrecacheModel(v)
	end
end

PrettyFuncs = {
	["randomizeviews"] = "Randomize Views",
	["lowergravity"] = "Lower Gravity",
	["deepfry"] = "Deep Fry",
	["inception"] = "Inception",
	["spawnzombies"] = "Spawn Zombies",
	["masterfov"] = "Master FOV",
	["zawarudo"] = "The World",
	["invisiblewarfare"] = "Invisible Warfare",
	["ragdolleveryone"] = "Ragdoll Everyone",
	["speedtime"] = "Speed up Time",
	["slowtime"] = "Slow down Time",
	["speedup"] = "Speed up Players",
	["slowdown"] = "Slow down Players",
	["reversecontrols"] = "Reverse Controls",
	["megaslap"] = "Mega Slap",
	["floorisice"] = "The Floor is Ice",
	["silenthill"] = "Silent Hill",
	["swappositions"] = "Swap Positions",
	["timeskip"] = "Time Skip",
	["upsidedowncams"] = "Upside Down Cameras",
	["bomberman"] = "Bomberman",
	["antfight"] = "Ant Fight",
	["bigheadmode"] = "Big Head Mode",
	["jellymode"] = "Jelly Mode",
	["paranoia"] = "Paranoia",
	["blindness"] = "Blindness",
	["deafness"] = "Deafness",
	["tinnitus"] = "Tinnitus",
	["bouncyjump"] = "Bouncy Jumps",
	["thirdperson"] = "Thirdperson Mode",
	["rainingbombs"] = "Raining Bombs",
	["crabinfestation"] = "Crab Infestation",
	["whoswho"] = "Who's Who?",
	["itsamystery"] = "it is a mystery",
	["earthquake"] = "Earthquake",
	["kamikaze"] = "Kamikaze",
	["mobamode"] = "MOBA Mode",
	["instakill"] = "Instakill",
	["reviveeveryone"] = "Revive Everyone",
	["bossmode"] = "Boss Mode",
	["tankcontrols"] = "Tank Controls",
	["randomsensitivity"] = "Random Sensitivity",
	["randomoverlay"] = "Random Overlay",
	["randomtexturize"] = "Random Texturize",
	["nearsightedness"] = "Nearsightedness",
	["3dmode"] = "3D Mode",
	["megabloom"] = "Graphics in 2013",
	["goodnightgirl"] = "Goodnight Girl",
	["punchscreen"] = "Screen Punch",
	["mathtime"] = "Math Time",
	["prophunt"] = "Prop Hunt",
	["phoon"] = "too much for zblock"
}

function IncrementActionCounter()
	SetGlobalInt("ActionCounter", GetGlobalInt("ActionCounter", 1) + 1)
end

hook.Add("StartCommand", "FuckWithControls", function(ply, cmd)
	if controlsReversed then
		//cmd:ClearMovement()
		local fwspeed = cmd:GetForwardMove()
		local sidespeed = cmd:GetSideMove()
		if cmd:KeyDown(IN_FORWARD) then
			//print("forward " .. fwspeed)
			cmd:SetForwardMove(-fwspeed)
			//print("MARKER ---- - -- - --")
		end
		if cmd:KeyDown(IN_BACK) then
			cmd:SetForwardMove(-fwspeed)
		end
		if cmd:KeyDown(IN_MOVELEFT) then
			//print(sidespeed)
			cmd:SetSideMove(-sidespeed)
		end
		if cmd:KeyDown(IN_MOVERIGHT) then
			//print(sidespeed)
			cmd:SetSideMove(-sidespeed)
		end
		//cmd:SetMouseWheel(-cmd:GetMouseWheel())
	end
	if TankControls then
		if cmd:KeyDown(IN_MOVELEFT) then
			local ang = cmd:GetViewAngles()
			ang.yaw = ang.yaw + 1
			cmd:SetSideMove(0)
			cmd:SetViewAngles(ang)
		end
		if cmd:KeyDown(IN_MOVERIGHT) then
			local ang = cmd:GetViewAngles()
			ang.yaw = ang.yaw - 1
			cmd:SetSideMove(0)
			cmd:SetViewAngles(ang)
		end
	end
end)

if CLIENT then
	hook.Add("InputMouseApply", "ReverseMouse", function(cmd, x, y, angle)
		if controlsReversed then
			//print(cmd:GetViewAngles()) 
			/* PITCH == UP (postive) AND DOWN (negative) */
			/* YAW == LEFT (adds until positive 180 then negative) AND RIGHT (subtracts from positive under 180)*/
			angle.pitch = math.Clamp(angle.pitch - y / 50, -89, 89)
			angle.yaw = angle.yaw + x / 50
			cmd:SetViewAngles(angle)
			return true
			//angle.pitch = 
		end
		if TankControls then
			angle.pitch = 0
			cmd:SetViewAngles(angle)
			return true
		end
		if RandomSensitivity then
			math.randomseed(os.time())
			local rand = math.random(5, 200)
			angle.pitch = math.Clamp(angle.pitch + y / rand, -89, 89)
			angle.yaw = angle.yaw - x / rand
			cmd:SetViewAngles(angle)
			return true
		end
	end)
end

net.Receive("ReverseControls", function()
	print("reversing controls")
	controlsReversed = true
	timer.Simple(ActionDuration, function()
		controlsReversed = false
	end)
end)

hook.Add("AntFight", "AntFightShared", function(scale) // bug: crouching hulls dont seem to set right?
	print("running antfight hook")
	for k, v in ipairs(player.GetAll()) do
		if not v:Alive() then continue end
		v:SetViewOffset(scale * Vector(0, 0, 64))
		v:SetViewOffsetDucked(scale * Vector(0, 0, 28))
		//print(v:GetHull())
		//	print(v:GetHullDuck())
		v:SetHull(scale * Vector(-16, -16, 0), scale * Vector(16, 16, 72))
		v:SetHullDuck(scale * Vector(-16, -16, 0), scale * Vector(-16, -16, 36))
		if SERVER then 
			v:SetStepSize(18 * scale)
		else
			local mat = Matrix()
			mat:Scale(Vector(scale, scale, scale))
			v:EnableMatrix("RenderMultiply", mat)
		end
	end
end)

net.Receive("AntFight", function()
	// why the fuck do i do it this way? did i have to and forgot?
	local scale = net.ReadFloat()
	hook.Run("AntFight", scale)
end)

local last_rand
function GetPseudoRandomNumber(max_num)
	math.randomseed(os.time())
	local rand = math.random(max_num)
	while last_rand == rand do
		rand = math.random(max_num)
	end
	last_rand = rand

	return rand
end

net.Receive("TankControls", function()
	TankControls = true
	timer.Simple(ActionDuration, function()
		TankControls = false
	end)
end)

net.Receive("RandomSensitivity", function()
	RandomSensitivity = true
	timer.Simple(ActionDuration, function()
		RandomSensitivity = false
	end)
end)

local GroundFrames = {} // from MrRanger's BHOP Mode
local function PlayerMove(ply,data)
	if not IsValid(ply) or not GetGlobalBool("PhoonMode", false) then return end

	local OnGround = ply:IsFlagSet(FL_ONGROUND)
	if OnGround and not GroundFrames[ply] then
		GroundFrames[ply] = 0
	elseif OnGround and GroundFrames[ply] then
		GroundFrames[ply] = GroundFrames[ply] + 1
		if GroundFrames[ply] > 4 then
			ply:SetDuckSpeed(0.4)
			ply:SetUnDuckSpeed(0.2)
		end
	end

	if OnGround or not ply:Alive() then return end
	
	GroundFrames[ply] = 0
	ply:SetDuckSpeed(0)
	ply:SetUnDuckSpeed(0)

	local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = data:GetForwardSpeed()
	local smove = data:GetSideSpeed()
	local strafing = false

	if data:KeyDown(IN_MOVERIGHT) then
		smove = (smove * 10) + 500
	elseif data:KeyDown(IN_MOVELEFT) then
		smove = (smove * 10) - 500
	end

	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local wishvel = forward * fmove + right * smove
	wishvel.z = 0

	local wishspeed = wishvel:Length()
	if wishspeed > data:GetMaxSpeed() then
		wishvel = wishvel * (data:GetMaxSpeed() / wishspeed)
		wishspeed = data:GetMaxSpeed()
	end

	local wishspd = wishspeed
	wishspd = math.Clamp(wishspd, 0, 128)

	local wishdir = wishvel:GetNormal()
	local current = data:GetVelocity():Dot(wishdir)

	local addspeed = wishspd - current
	if addspeed <= 0 then return end

	local accelspeed = 120 * FrameTime() * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	local vel = data:GetVelocity()
	vel = vel + (wishdir * accelspeed)
	data:SetVelocity(vel)
	
	return false
end
hook.Add("Move","StrafeMovement",PlayerMove)