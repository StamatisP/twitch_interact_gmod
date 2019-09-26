AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/player/phoenix.mdl")
	self:SetPlyName("null")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	local phys = self:GetPhysicsObject()
	phys:Wake()
	phys:EnableMotion(false)
end

function ENT:Touch(entity)
	if entity:IsPlayer() then
		if entity:Nick() == self:GetPlyName() then
			net.Start("WhosWho")
				net.WriteBool(false)
			net.Send(entity)
			SpawnPlayer(entity)
			entity:SetPos(self:GetPos())
			self:Remove()
		end
	end
end