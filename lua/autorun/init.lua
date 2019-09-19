AddCSLuaFile()
print("shared file")
local controlsReversed = false

local ActionDuration = 15 // CHANGE THIS IN ACTIONS TOO

do
	util.PrecacheSound( "the_world_time_stop.mp3" )
	util.PrecacheSound( "the_world_time_start.mp3" )
	util.PrecacheSound("spy_cloak.wav")
	util.PrecacheSound("spy_uncloak.wav")
	util.PrecacheSound("inception.mp3")
end

PrettyFuncs = {
	["randomizeviews"] = "Randomize Views",
	["lowergravity"] = "Lower Gravity",
	["fuckwithscreen"] = "Fuck Their Screens",
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
	["jellymode"] = "Jelly Mode"
}

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
	end)
end

net.Receive("ReverseControls", function()
	print("reversing controls")
	controlsReversed = true
	timer.Simple(ActionDuration, function()
		controlsReversed = false
	end)
end)

hook.Add("AntFight", "AntFightShared", function(scale)
	print("running antfight hook")
	for k, v in ipairs(player.GetAll()) do
		v:SetViewOffset(scale * Vector(0, 0, 64))
		v:SetViewOffsetDucked(scale * Vector(0, 0, 28))
		v:SetHull(scale * Vector(-16, -16, 0), 0.3 * Vector(16, 16, 72))
		v:SetHullDuck(scale * Vector(-16, -16, 0), 0.3 * Vector(-16, -16, 36))
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
	local scale = net.ReadFloat()
	hook.Run("AntFight", scale)
end)