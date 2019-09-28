include("shared.lua")

function ENT:Initialize()
	self.initialized = true
	self:SetModelScale(2, 0)
end

function ENT:Think()
	if not self.initialized then
		self:Initialize()
	end
end

local bombmat = Material("icon16/bomb.png")

function ENT:Draw()
	cam.IgnoreZ(true)
	self:DrawModel()

	/*cam.Start3D2D(self:GetPos(), self:GetAngles(), 10)
		surface.SetMaterial(bombmat)
		local screenpos = self:GetPos():ToScreen()
		surface.DrawTexturedRect(screenpos.x, screenpos.y, 16, 16)
	cam.End3D2D()*/

	cam.IgnoreZ(false)
end