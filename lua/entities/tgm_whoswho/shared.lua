ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Who's Who Ent"
ENT.Author = "Mineturtle"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "PlyName")
end