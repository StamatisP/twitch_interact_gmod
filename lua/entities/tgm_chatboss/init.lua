AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/kleiner.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetUseType(SIMPLE_USE)
	local phys = self:GetPhysicsObject()
	phys:Wake()
	phys:EnableMotion(false)
	self.soundid = self:StartLoopingSound("chatboss_loop")
	self:SetHealth(9999)
	self.speed = 4 * (GetGlobalInt("ChatBossStreak", 1) * 0.75)
end

local function GetAlivePlayers()
	local alivePlayers = {}
	for k, v in ipairs(player.GetAll()) do
		if v:Alive() then table.insert(alivePlayers, v) end
	end

	return alivePlayers
end

function ENT:ApproachVector(target)
	if target then
		local selfpos = self:GetPos()
		local targetpos = target:GetPos()
		selfpos.x = math.Approach(selfpos.x, targetpos.x, self.speed)
		selfpos.y = math.Approach(selfpos.y, targetpos.y, self.speed)
		selfpos.z = math.Approach(selfpos.z, targetpos.z, self.speed)
		return selfpos
	end
end

function ENT:Think()
	self:FindPlayer()
	if self:Health() <= 0 then
		SetGlobalInt("ChatBossStreak", GetGlobalInt("ChatBossStreak", 1) + 1)
		self:Remove()
	else
		if self:GetTargetPlayer() and self:GetTargetPlayer():Alive() then
			self:SetPos(self:ApproachVector(self:GetTargetPlayer()))
			self:PointAtEntity(self:GetTargetPlayer())
		else
			print("chat boss succeeded!")
			PrintMessage(HUD_PRINTTALK, "The Chat Boss has succeeded!")
			SetGlobalInt("ChatBossStreak", 1)
			self:Remove()
		end
	end
	local nearbyents = ents.FindInSphere(self:GetPos(), 250)
	if nearbyents then
		for k, v in pairs(nearbyents) do
			if v:GetClass() == "prop_physics" or v:IsPlayer() then
				local dmg = math.Remap(v:GetPos():DistToSqr(self:GetPos()), 0, 62500, 0, 2) - 2
				v:TakeDamage(math.abs(dmg), self, self)
			end
		end
	end
	self:NextThink(CurTime() + 0.05)
	return true
end

function ENT:FindPlayer()
	local closestdist
	for k, v in ipairs(GetAlivePlayers()) do
		local dist = self:GetPos():DistToSqr(v:GetPos())
		if not closestdist then
			closestdist = dist
		end
		if dist <= closestdist then
			self:SetTargetPlayer(v)
		end
	end
	if TGM_Streamer then
		self:SetTargetPlayer(TGM_Streamer)
	end
end

function ENT:OnTakeDamage(damage)
	if damage:IsDamageType(DMG_BULLET) or damage:IsDamageType(DMG_BLAST) then
		local dmg = damage:GetDamage()
		dmg = math.Clamp(dmg, 1, 100)
		dmg = dmg * 4
		local fwd = self:GetAngles():Forward()
		local selfpos = self:GetPos()
		local newpos = selfpos
		newpos = Vector( selfpos.x - (dmg * fwd.x), selfpos.y - (dmg * fwd.y), selfpos.z - (dmg * fwd.z))
		//print(fwd)
		//print("Current pos: " .. tostring(selfpos))
		//print("Predicted pos: " .. tostring(newpos))
		self:SetPos(newpos)
		//print("New pos: " .. tostring(self:GetPos()))
		//self:SetPos((fwd * dmg) - self:GetPos())
		self:SetHealth(self:Health())
	end
end

function ENT:OnRemove()
	net.Start("ChatBoss")
		net.WriteBool(false)
		net.WriteEntity(nil)
	net.Broadcast()
	self:StopLoopingSound(self.soundid)
end