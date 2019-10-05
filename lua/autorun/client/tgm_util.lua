print("util load")
local lastTexture = nil
local mat_Overlay = nil

function DrawMaterialOverlayVR( texture, refractamount )

	if ( texture ~= lastTexture or mat_Overlay == nil ) then
		mat_Overlay = Material( texture )
		lastTexture = texture
	end

	if ( mat_Overlay == nil || mat_Overlay:IsError() ) then return end

	render.UpdateScreenEffectTexture()

	// FIXME: Changing refract amount affects textures used in the map/models.
	mat_Overlay:SetFloat( "$envmap", 0 )
	mat_Overlay:SetFloat( "$envmaptint", 0 )
	mat_Overlay:SetFloat( "$refractamount", refractamount )
	mat_Overlay:SetInt( "$ignorez", 1 )

	render.SetMaterial( mat_Overlay )
	render.DrawScreenQuadEx(0, 0, ScrW()/2, ScrH())
	render.DrawScreenQuadEx(ScrW()/2, 0, ScrW()/2, ScrH())
end

local matMaterial = Material( "pp/texturize" )
matMaterial:SetTexture( "$fbtexture", render.GetScreenEffectTexture() )

function DrawTexturizeVR( scale, pMaterial )

	render.UpdateScreenEffectTexture()

	matMaterial:SetFloat( "$scalex", ( ScrW() / 64 ) * scale )
	matMaterial:SetFloat( "$scaley", ( ScrH() / 64 / 8 ) * scale )
	matMaterial:SetTexture( "$basetexture", pMaterial:GetTexture( "$basetexture" ) )

	render.SetMaterial( matMaterial )
	render.DrawScreenQuad()
end