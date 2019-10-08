print("util load")
local lastTexture = nil
local mat_Overlay = nil
local mat_Downsample = Material( "pp/downsample" )
mat_Downsample:SetTexture( "$fbtexture", render.GetScreenEffectTexture() )

local mat_Bloom = Material( "pp/bloom" )
local tex_Bloom0 = render.GetBloomTex0()
// the draw functions are called twice per frame, if i print the scrw its 960, so i have no clue

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
	//render.DrawScreenQuadEx(0, 0, ScrW(), ScrH())
	render.DrawScreenQuadEx(ScrW(), 0, ScrW(), ScrH())
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

function DrawBloomVR( darken, multiply, sizex, sizey, passes, color, colr, colg, colb )

	-- No bloom for crappy gpus
	if ( !render.SupportsPixelShaders_2_0() ) then return end

	-- Copy the backbuffer to the screen effect texture
	render.UpdateScreenEffectTexture()

	-- Store the render target so we can swap back at the end
	local OldRT = render.GetRenderTarget()

	-- The downsample material adjusts the contrast
	mat_Downsample:SetFloat( "$darken", darken )
	mat_Downsample:SetFloat( "$multiply", multiply )

	-- Downsample to BloomTexture0
	render.SetRenderTarget( tex_Bloom0 )

	render.SetMaterial( mat_Downsample )
	render.DrawScreenQuadEx(0, 0, ScrW() / 2, ScrH())
	render.DrawScreenQuadEx(ScrW() / 2, 0, ScrW() / 2, ScrH())

	render.BlurRenderTarget( tex_Bloom0, sizex, sizey, passes )

	render.SetRenderTarget( OldRT )

	mat_Bloom:SetFloat( "$levelr", colr )
	mat_Bloom:SetFloat( "$levelg", colg )
	mat_Bloom:SetFloat( "$levelb", colb )
	mat_Bloom:SetFloat( "$colormul", color )
	mat_Bloom:SetTexture( "$basetexture", tex_Bloom0 )

	render.SetMaterial( mat_Bloom )
	render.DrawScreenQuad()

end