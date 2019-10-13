ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Chat Boss"
ENT.Author = "Mineturtle"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "TargetPlayer")
end