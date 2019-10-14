include("shared.lua")

function ENT:Initialize()
	//self:SetPredictable(true)
end

local wMat = Material("models/debug/debugwhite")
function ENT:Draw()
	cam.IgnoreZ(true)
	render.SuppressEngineLighting(true)
	render.SetMaterial(wMat)
	render.SetColorModulation(0, 0, 0)
	self:DrawModel()
	cam.IgnoreZ(false)
	render.SetColorMaterial()
	render.CullMode(1)
	render.DrawSphere(self:GetPos(), 250, 16, 16, Color(0, 0, 0), true)
	render.CullMode(0)
	render.DrawSphere(self:GetPos(), 250, 16, 16, Color(0, 0, 0), true)
	render.SuppressEngineLighting(false)
end