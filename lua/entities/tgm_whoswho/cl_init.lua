include("shared.lua")

local function Draw3DText( pos, ang, scale, text, flipView )
	if ( flipView ) then
		-- Flip the angle 180 degrees around the UP axis
		ang:RotateAroundAxis( Vector( 0, 0, 1 ), 180 )
	end

	cam.Start3D2D( pos, ang, scale )
		-- Actually draw the text. Customize this to your liking.
		draw.DrawText( text, "DermaLarge", 0, 0, Color( 0, 255, 0, 255 ), TEXT_ALIGN_CENTER )
	cam.End3D2D()
end

function ENT:Initialize()
	self.initialized = true
	self.isLocalPlayer = false

	//print(self:GetPlyName())
	if self:GetPlyName() == LocalPlayer():Nick() then
		self.isLocalPlayer = true
	end
end

function ENT:Think()
	if not self.initialized then
		self:Initialize()
	end
end

function ENT:Draw()
	if self.isLocalPlayer then
		cam.IgnoreZ(true)
		self:DrawModel()

		local text = "Your Body is Here!"

		-- The position. We use model bounds to make the text appear just above the model. Customize this to your liking.
		local mins, maxs = self:GetModelBounds()
		local pos = self:GetPos() + Vector( 0, 0, maxs.z + 50 )

		-- The angle
		//local ang = Angle( 0, SysTime() * 100 % 360, 90 )
		local ang = LocalPlayer():EyeAngles() + Angle(0, 90, 90)
		ang.pitch = 0

		local scale = math.Clamp(LocalPlayer():GetPos():DistToSqr(self:GetPos()) / 100000, 1, 3)

		self:SetAngles(Angle(0, SysTime() * 100 % 360, 0))

		-- Draw front
		//Draw3DText( pos, ang, 1, text, false )
		-- DrawDraw3DTextback
		Draw3DText( pos, ang, scale, text, true )
		cam.IgnoreZ(false)
	else
		self:DrawModel()
	end	
end