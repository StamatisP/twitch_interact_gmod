include("shared.lua")
local light

function ENT:Initialize()
	self.initialized = true
	self:SetModelScale(2, 0)

	light = DynamicLight(self:EntIndex(), false)
	if light then
		light.pos = self:GetPos()
		light.r = 255
		light.g = 0
		light.b = 0
		light.brightness = 9
		light.Decay = -1
		light.Size = 512
		light.DieTime = CurTime() + 15
	end
end

function ENT:Think()
	if not self.initialized then
		self:Initialize()
	end
end

function ENT:Draw()
	cam.IgnoreZ(true)
	//self:DrawModel()

	if light then
		light.pos = self:GetParent():GetPos()
	end

	/*cam.Start3D2D(self:GetPos(), self:GetAngles(), 10)
		surface.SetMaterial(bombmat)
		local screenpos = self:GetPos():ToScreen()
		surface.DrawTexturedRect(screenpos.x, screenpos.y, 16, 16)
	cam.End3D2D()*/

	cam.IgnoreZ(false)
end