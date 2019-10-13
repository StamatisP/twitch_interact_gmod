include("shared.lua")

function ENT:Initialize()
	//self:SetPredictable(true)
end


/*local lerp = 0
function ENT:Think()
	local nextpos = self:GetTargetPlayer():GetPos()
	
	if lerp < 1 then
		lerp = lerp + FrameTime() * 0.003
	end
	
	if lerp > 1 then lerp = 0 end
	local newpos = LerpVector(lerp, self:GetPos(), nextpos)
	self:SetPos(newpos)
end*/

local wMat = Material("models/debug/debugwhite")
function ENT:Draw()
	render.SuppressEngineLighting(true)
	render.SetMaterial(wMat)
	render.SetColorModulation(0, 0, 0)
	self:DrawModel()
	render.SuppressEngineLighting(false)
end