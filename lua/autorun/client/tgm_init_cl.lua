print("client load!")

CreateClientConVar("tgm_chat", "0", true, true, "If you get Twitch chat printed to your chat.")
local bombmat = Material("icon16/bomb.png")
local wMat = Material("models/debug/debugwhite")

local voting_time = false
local isDoubleVote = false

local ScreenFuck = false

local SilentHill = false
local Fog_End = 5600
local Fog_Density = 0
local Paranoia = false
local ThirdPerson = false
local WhosWho = false
local KamikazeVar = false
local MobaMode = false
local IsBoss = false
local MegaBloom = false
local RandomTexturize = false
local TxtEffect
local RandomOverlay = false
local RndOverlay
local RndRefract
local Boss_CurrentMusic

local LoadedSounds = {}

local votes = {}
ActionDuration = ActionDuration or 15
local actionTime = actionTime or 0
local timeText

local f, f2
local label1, label2, label3, label4
local progbar1, progbar2, progbar3, progbar4

/* COLOR MODIFY TABS */
local deepfryTab = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1.35,
	[ "$pp_colour_colour" ] = 5,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}
local paranoiaTab = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 2,
	[ "$pp_colour_colour" ] = 0,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}
local silenthillTab = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 0.3,
	[ "$pp_colour_mulr" ] = 0.3,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}
local whoswhoTab = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0.18,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0.3,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}
local kamikazeTab = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 0.3,
	[ "$pp_colour_mulr" ] = 1,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}

local TwitchColors = {
	Color(255, 0, 0),
	Color(0, 0, 255),
	Color(0, 128, 0),
	Color(178, 34, 34),
	Color(255, 127, 80),
	Color(154, 205, 50),
	Color(255, 69, 0),
	Color(46, 139, 87),
	Color(218, 165, 32),
	Color(210, 105, 30),
	Color(95, 158, 160),
	Color(30, 144, 255),
	Color(255, 105, 180),
	Color(138, 43, 226),
	Color(0, 255, 127)
}

surface.CreateFont( "FuncTitle", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = ScrW() / 76,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})

surface.CreateFont("VRText", {
	font = "Verdana", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 15,
	weight = 200,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})

local MusicChannel
local boss_music = {
	[1] = {song = "music/hl1_song10.mp3", duration = 104},
	[2] = {song = "music/hl2_song12_long.mp3", duration = 74},
	[3] = {song = "music/hl2_song14.mp3", duration = 159},
	[4] = {song = "music/hl2_song29.mp3", duration = 135},
	[5] = {song = "music/hl2_song20_submix4.mp3", duration = 139}
}

local CurrentPostProcess = {}
local pp_effects = {
	[1] = "models/props_c17/fisheyelens",
	[2] = "models/shadertest/shader4",
	[3] = "models/shadertest/shader5",
	[4] = "effects/strider_pinch_dudv",
	[5] = "models/shadertest/shader3",
	[6] = "models/props_combine/tprings_globe",
	[7] = "models/props_combine/com_shield001a",
	[8] = "models/props_combine/stasisshield_sheet",
	[9] = "models/props_lab/tank_glass001",
	[10] = "overlays/whirl"
}

local txt_effects = {
	[1] = "pp/texturize/rainbow.png",
	[2] = "pp/texturize/pinko.png",
	[3] = "pp/texturize/squaredo.png"
}

/* HOOKS */

local function TGMRender()
	if ScreenFuck then
		//print("please")
		DrawColorModify(deepfryTab)
		DrawSobel(0.5)
		DrawSharpen(3, 3)
	end

	if SilentHill then
		DrawColorModify(silenthillTab)
		DrawMaterialOverlay( "overlays/vignette01", 1 )
	end

	if Paranoia then
		DrawColorModify(paranoiaTab)
		DrawSharpen(1.3, 1.3)
		DrawMaterialOverlay( "overlays/vignette01", 1 )
	end
	
	if WhosWho then
		DrawColorModify(whoswhoTab)
		DrawMaterialOverlay("overlays/vignette01", 1)
	end

	if KamikazeVar then
		DrawColorModify(kamikazeTab)
		DrawMaterialOverlay("overlays/vignette01", 1)
		cam.Start3D()
			cam.IgnoreZ(true)
			render.SuppressEngineLighting(true)

			for k, v in pairs(player.GetAll()) do
				if v == LocalPlayer() or not v:Alive() then continue end

				render.MaterialOverride(wMat)
				render.SetColorModulation(1, 0, 0)
				v:DrawModel()
				render.MaterialOverride(nil) // to fix renderview breaking
			end

			cam.IgnoreZ(false)
			render.SuppressEngineLighting(false)
		cam.End3D()
	end

	if IsBoss then
		cam.Start3D()
			cam.IgnoreZ(true)
			render.SuppressEngineLighting(true)

			for k, v in pairs(player.GetAll()) do
				if v == LocalPlayer() or not v:Alive() then continue end
				render.MaterialOverride(wMat)
				render.SetColorModulation(1, 0, 0)
				v:DrawModel()
				render.MaterialOverride(nil) // to fix renderview breaking
			end

			cam.IgnoreZ(false)
			render.SuppressEngineLighting(false)
		cam.End3D()
	end

	if MegaBloom then
		//RenderDoF(LocalPlayer():GetShootPos(), Angle(0, 0, 0), LocalPlayer():GetShootPos() + Vector(9, 0, 0), 0.5, 2, 2, false, nil, 90)
		//print("bruh")
		DrawBloom(-0.1, 1, 5, 5, 4, 3, 1, 1, 1)
	end
	if RandomTexturize then
		if g_VR and g_VR.active then
			DrawTexturizeVR(1, Material(TxtEffect))
		else
			DrawTexturize(1, Material(TxtEffect))
		end
	end
	if RandomOverlay then
		if g_VR and g_VR.active then
			DrawMaterialOverlayVR(RndOverlay, RndRefract)
		else
			DrawMaterialOverlay(RndOverlay, RndRefract)
		end
	end
end

local function TGMPostRender()
end

hook.Add("PostDrawEffects", "TGMRender", TGMRender)
hook.Add("PostRender", "TGMPostRender", TGMPostRender)

hook.Add("OnPlayerChat", "check_tgm_chat", function(ply, text, teamchat, isdead)
	if text == "!chat" then
		if LocalPlayer() != ply then return end
		if GetConVar("tgm_chat"):GetBool() then
			GetConVar("tgm_chat"):SetBool(false)
			chat.AddText("Twitch chat disabled.")
		else
			GetConVar("tgm_chat"):SetBool(true)
			chat.AddText("Twitch chat enabled.")
		end
		return true
	end
end)

function SetupWorldFog()
	if SilentHill then
		//print("world fog")
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( 0 )
		render.FogEnd( Fog_End )
		render.FogMaxDensity( Fog_Density )
		render.FogColor( 0.98 * 255, 0.98 * 255, 0.98 * 255)

		//return true
	elseif Paranoia then
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( 0 )
		render.FogEnd( Fog_End )
		render.FogMaxDensity( Fog_Density )
		render.FogColor( 0, 0, 0)

		//return true
	else
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( 0 )
		render.FogEnd( Fog_End )
		render.FogMaxDensity( Fog_Density )
		render.FogColor( 0.6 * 255, 0.7 * 255, 0.8 * 255)

		//return true
	end
	return true
end

function SetupSkyFog( skyboxscale )
	if SilentHill then
		//print("skybox fog")
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( 0 * skyboxscale )
		render.FogEnd( Fog_End * skyboxscale )
		render.FogMaxDensity( Fog_Density )
		render.FogColor( 0.98 * 255, 0.98 * 255, 0.98 * 255)

		//return true
	elseif Paranoia then
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( 0 * skyboxscale )
		render.FogEnd( Fog_End * skyboxscale )
		render.FogMaxDensity( Fog_Density )
		render.FogColor( 0, 0, 0)

		//return true
	else
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( 0 * skyboxscale )
		render.FogEnd( Fog_End * skyboxscale )
		render.FogMaxDensity( Fog_Density )
		render.FogColor( 0.6 * 255, 0.7 * 255, 0.8 * 255)

		//return true
	end
	return true
end

hook.Add( "SetupWorldFog", "worldfog", SetupWorldFog )
hook.Add( "SetupSkyboxFog", "skyboxfog", SetupSkyFog )

local function TGMCalcView(ply, pos, angles, fov)
	if ThirdPerson then
		local view = {}

		view.origin = pos - (angles:Forward() * 100)
		view.drawviewer = true

		return view
	elseif MobaMode then
		local view = {}

		view.origin = pos + Vector(0, 0, 350)
		view.angles = Angle(90, -180, 0)
		view.drawviewer = true

		return view
	end
end

hook.Add("CalcView", "TGMCalcView", TGMCalcView)

hook.Add("PostDrawTranslucentRenderables", "KamikazeBomb", function(bDepth, bSkybox)
	for k, v in ipairs(player.GetAll()) do
		if v.Kamikaze then
			render.SetMaterial(bombmat)
			local dir = LocalPlayer():GetForward() * -1
			local pos = v:GetPos()
			pos.z = pos.z + 128

			cam.IgnoreZ(true)
			render.DrawQuadEasy(pos, dir, 64, 64, Color(255, 255, 255, 255), 180)
			cam.IgnoreZ(false)
		end
	end
end)

hook.Add("PostPlayerDraw", "DrawMobaLines", function(ply)
	if not IsValid(ply) then return end
	if MobaMode then
		local eyetrace = ply:GetEyeTrace()
		render.DrawLine(ply:GetShootPos(), eyetrace.HitPos, Color(255, 0, 0))
	end
end)

/* VOTING */

local FuncLabel = {}
function FuncLabel:Init()
	self:SetSize(750, 30)
	self:SetFont("FuncTitle")
	self:SetText("")
	self:SetTextColor(Color(30, 255, 30))
end
function FuncLabel:SetText2(txt)
	self.text2 = txt
end
function FuncLabel:GetText2()
	return self.text2
end
function FuncLabel:Paint(w, h)
	draw.SimpleText(self:GetText2(), "FuncTitle", 1, 1, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(self:GetText2(), "FuncTitle", 0, 0, Color(30, 255, 30), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local VoteMenu = {}
function VoteMenu:Init()
	self.f = vgui.Create("DFrame", self)
	if isDoubleVote then
		self.f:SetSize(750, 350)
	else
		self.f:SetSize(500, 350)
	end
	local frameWidth, frameHeight = self.f:GetSize()
	self.f:SetTitle("Vote Menu")
	//self.f:SetPos(0, 0)
	self.f:ShowCloseButton(false)
	self.f.Paint = function(s, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(60, 60, 60, 100))
	end
	self.label1 = vgui.Create("FuncLabel", self)
	self.label1:SetPos(15, 30)

	self.progbar1 = vgui.Create("DProgress", self)
	self.progbar1:SetPos(25, 60)
	self.progbar1:SetSize(frameWidth - 50, 40)

	self.label2 = vgui.Create("FuncLabel", self)
	self.label2:SetPos(15, 110)

	self.progbar2 = vgui.Create("DProgress", self)
	self.progbar2:SetPos(25, 140)
	self.progbar2:SetSize(frameWidth - 50, 40)

	self.label3 = vgui.Create("FuncLabel", self)
	self.label3:SetPos(15, 190)

	self.progbar3 = vgui.Create("DProgress", self)
	self.progbar3:SetPos(25, 220)
	self.progbar3:SetSize(frameWidth - 50, 40)

	self.label4 = vgui.Create("FuncLabel", self)
	self.label4:SetPos(15, 270)

	self.progbar4 = vgui.Create("DProgress", self)
	self.progbar4:SetPos(25, 300)
	self.progbar4:SetSize(frameWidth - 50, 40)

	self:InvalidateLayout(true)
	self:SizeToChildren(true, true)
end
function VoteMenu:UpdateVotes(tab)
	self.maxVotes = 0
	for k, v in ipairs(tab) do
		self.maxVotes = self.maxVotes + v.value
	end
	if not self.label1 then return end
	if isDoubleVote then
		self.label1:SetText2( (PrettyFuncs[tab[1].name] or tab[1].name) .. " + " .. (PrettyFuncs[tab[1].name2] or tab[1].name2) .. " (!" .. tab[1].name .. ")")
		self.label2:SetText2( (PrettyFuncs[tab[2].name] or tab[2].name) .. " + " .. (PrettyFuncs[tab[2].name2] or tab[2].name2) .. " (!" .. tab[2].name .. ")")
		self.label3:SetText2( (PrettyFuncs[tab[3].name] or tab[3].name) .. " + " .. (PrettyFuncs[tab[3].name2] or tab[3].name2) .. " (!" .. tab[3].name .. ")")
		self.label4:SetText2( (PrettyFuncs[tab[4].name] or tab[4].name) .. " + " .. (PrettyFuncs[tab[4].name2] or tab[4].name2) .. " (!" .. tab[4].name .. ")")
	else
		self.label1:SetText2( (PrettyFuncs[tab[1].name] or tab[1].name) .. " (!" .. tab[1].name .. ")")
		self.label2:SetText2( (PrettyFuncs[tab[2].name] or tab[2].name) .. " (!" .. tab[2].name .. ")")
		self.label3:SetText2( (PrettyFuncs[tab[3].name] or tab[3].name) .. " (!" .. tab[3].name .. ")")
		self.label4:SetText2( (PrettyFuncs[tab[4].name] or tab[4].name) .. " (!" .. tab[4].name .. ")")
	end

	self.progbar1:SetFraction(tab[1].value / self.maxVotes)
	self.progbar2:SetFraction(tab[2].value / self.maxVotes)
	self.progbar3:SetFraction(tab[3].value / self.maxVotes)
	self.progbar4:SetFraction(tab[4].value / self.maxVotes)
end
function VoteMenu:Paint(wide, tall)
	//surface.SetDrawColor(Color(255, 0, 0))
	//surface.DrawRect(0, 0, wide, tall)
end

vgui.Register("FuncLabel", FuncLabel, "DLabel")
vgui.Register("VoteMenuDerma", VoteMenu, "Panel")

local function VoteDerma(isDoubleVote)
	if not isDoubleVote then isDoubleVote = false end
	if f then
		if f:IsValid() then f:Clear() end
	end
	f = vgui.Create("VoteMenuDerma")

	if g_VR and g_VR.active then
		f:SetPos(0, 0)
		VRUtilMenuOpen("VoteMenu", 1024, 1024, f, 1, Vector(0,0,0), Angle(0,-90,50), 0.03, false, nil)
		VRUtilMenuRenderPanel("VoteMenu")
		f2 = vgui.Create("VoteMenuDerma")
		local frameWidth, frameHeight = f2.f:GetSize()
		f2:SetPos(ScrW() - frameWidth, 0)
	else
		local frameWidth, frameHeight = f.f:GetSize()
		f:SetPos(ScrW() - frameWidth, 0)
	end
end

net.Receive("VoteDerma", function()
	isDoubleVote = net.ReadBool()
	local len = net.ReadUInt(16)
	local data = net.ReadData(len)
	if not data then ErrorNoHalt("why is data nil") end
	local json = util.Decompress(data)
	if not json then ErrorNoHalt("why is json nil???") end
	votes = util.JSONToTable(json)
	print("derma time")
	voting_time = true
	surface.PlaySound("plats/elevbell1.wav")
	VoteDerma(isDoubleVote)
end)

net.Receive("UpdateDerma", function()
	local len = net.ReadUInt(16)
	local data = net.ReadData(len)
	if not data then ErrorNoHalt("why is data nil") end
	local json = util.Decompress(data)
	if not json then ErrorNoHalt("why is json nil???") end
	local votes = util.JSONToTable(json)
	f:UpdateVotes(votes)
	if g_VR and g_VR.active then
		f2:UpdateVotes(votes)
		VRUtilMenuRenderPanel("VoteMenu")
	end
	//PrintTable(votes)
end)

net.Receive("EndVoting", function()
	f.f:Clear()
	f:Remove()
	if g_VR and g_VR.active then
		f2.f:Clear()
		f:Remove()
		VRUtilMenuClose("VoteMenu")
	end
end)

/* NET RECEIVES */

net.Receive("FuckWithScreen", function()
	ScreenFuck = true
	print("this be runnin")
	timer.Simple(ActionDuration, function()
		ScreenFuck = false
	end)
end)

net.Receive("PrintTwitchChat", function()
	local user = net.ReadString()
	local message = net.ReadString()
	local capped_user = string.gsub(user, "^%l", string.upper)
	math.randomseed(string.byte(user))
	chat.AddText(Color(140, 105, 204), "[", TwitchColors[math.random(#TwitchColors)], capped_user .. ": ", Color(255, 255, 255), message, Color(140, 105, 204), "]")
end)

net.Receive("ZaWarudoSound", function()
	local bool = net.ReadBool()
	if bool then
		surface.PlaySound("the_world_time_stop.mp3")
	else
		surface.PlaySound("the_world_time_start.mp3")
	end
end)	

local function PlayLoopingSound(soundname)
	local sound

	if not LoadedSounds[soundname] then
		sound = CreateSound(game.GetWorld(), soundname)
		if sound then
			sound:SetSoundLevel(0)
			LoadedSounds[soundname] = sound
		end
	else
		sound = LoadedSounds[soundname]
	end
	if sound then
		sound:Stop()
		//sound:PlayEx(volume, 100)
	end
	return sound
end

net.Receive("SilentHill", function()
	SilentHill = true
	math.randomseed(os.time())
	local rndsong = math.random(1, 3)
	surface.PlaySound("silenthill"..rndsong..".mp3")
	//LocalPlayer():ChatPrint("The fog is rolling in...")
	timer.Create("fog_end_lerp", 0.05, 0, function()
		if Fog_End <= 280 then
			timer.Destroy("fog_end_lerp")
			return
		end
		Fog_End = math.Approach(Fog_End, 280, -70)
		Fog_Density = math.Approach(Fog_Density, 0.99, 0.025)
	end)
	timer.Simple(ActionDuration, function()
		//LocalPlayer():ChatPrint("It's finally clearing up.")
		timer.Create("fog_end_lerp_2", 0.05, 0, function()
			if Fog_Density <= 0 then
				timer.Destroy("fog_end_lerp_2")
				SilentHill = false
				return
			end
			Fog_End = math.Approach(Fog_End, 5600, 70)
			Fog_Density = math.Approach(Fog_Density, 0, -0.025)
		end)
	end)
end)

net.Receive("PlayCloakSound", function()
	local isCloak = net.ReadBool()
	if isCloak then
		if file.Exists("sound/spy_cloak.wav", "GAME") then
			surface.PlaySound("spy_cloak.wav")
		else
			surface.PlaySound("invis_on.mp3")
		end
	else
		if file.Exists("sound/spy_cloak.wav", "GAME") then
			surface.PlaySound("spy_uncloak.wav")
		else
			surface.PlaySound("invis_off.mp3")
		end
	end
end)

net.Receive("Inception", function()
	surface.PlaySound("inception.mp3")
end)

net.Receive("Paranoia", function()
	Paranoia = true
	math.randomseed(os.time())
	local rndvo = math.random(1, 5)
	local rndstart = math.random(1, 2)
	local rndloop = math.random(1, 4)
	local loopsnd = PlayLoopingSound("paranoia_loop_"..rndloop..".wav")
	surface.PlaySound("paranoia_vo_"..rndvo..".mp3")
	surface.PlaySound("paranoia_start_"..rndstart..".mp3")
	loopsnd:PlayEx(0.8, 100)
	timer.Create("fog_end_lerp_paranoia", 0.05, 0, function()
		if Fog_End <= 280 then
			LocalPlayer():SetDSP(31, false)
			loopsnd:SetDSP(0)
			timer.Destroy("fog_end_lerp_paranoia")
			return
		end
		Fog_End = math.Approach(Fog_End, 280, -70)
		Fog_Density = math.Approach(Fog_Density, 1, 0.025)
	end)
	timer.Simple(ActionDuration, function()
		surface.PlaySound("paranoia_end_1.mp3")
		timer.Create("fog_end_lerp_2_paranoia", 0.05, 0, function()
			if Fog_Density <= 0 then
				loopsnd:FadeOut(1)
				timer.Destroy("fog_end_lerp_2_paranoia")
				LocalPlayer():SetDSP(0, false)
				Paranoia = false
				return
			end
			Fog_End = math.Approach(Fog_End, 5600, 70)
			Fog_Density = math.Approach(Fog_Density, 0, -0.025)
		end)
	end)
end)

net.Receive("Thirdperson", function()
	ThirdPerson = true
	timer.Simple(ActionDuration, function()
		ThirdPerson = false
	end)
end)

net.Receive("WhosWho", function()
	WhosWho = net.ReadBool()
	local loopsound = PlayLoopingSound("whoswho_loop.wav")
	hook.Add("TGMTimerTick", "WhosWhoTick", function(actionTime)
		if WhosWho then
			whoswhoTab["$pp_colour_colour"] = math.Clamp(actionTime / 30, 0.01, 1)
			whoswhoTab["$pp_colour_brightness"] = Lerp(actionTime / 30, -0.25, 0.18)
		end
	end)
	if WhosWho then
		surface.PlaySound("whoswho_sting.mp3")
		if GetGlobalInt("ActionCounter", 1) % 10 == 0 then
			LocalPlayer():EmitSound("whoswho_jingle.mp3", 0, 100, 0.4, CHAN_AUTO)
		else
			timer.Simple(3, function()
				loopsound:PlayEx(0.5, 100)
			end)
		end
	else
		print("ending")
		loopsound:FadeOut(1)
		hook.Remove("TGMTimerTick", "WhosWhoTick")
		timer.Destroy("TimerLower")
	end
end)

net.Receive("StartTimer", function()
	actionTime = net.ReadFloat()
	actiontime = actionTime or 15
	hook.Run("TGMTimerStart", actionTime)
	hook.Run("TGMTimerTick", actionTime)

	local guiScale = ScrW() / 1920
	if not timeText then
		timeText = vgui.Create("DPanel")
		timeText:SetSize(32, 32)
		timeText:SetPos(ScrW() / 2, 300 / guiScale)
		timeText:CenterHorizontal(0.5)
		timeText.Paint = function(self, w, h)
			if g_VR and g_VR.active then
				surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
				surface.DrawRect(0,0,w,h)
				//print(actionTime)
				draw.SimpleText(actionTime, "ChatFont", 0, 0, Color(255, 170, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			else
				draw.SimpleTextOutlined(actionTime, "DermaLarge", 2, 2, Color(255, 170, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0))
			end
		end
		if g_VR and g_VR.active then
			/*local testpanel = vgui.Create("DPanel")
			testpanel:SetPos(0, 0)
			testpanel:SetSize(64, 64)
			function testpanel:Paint(w, h)
				surface.SetDrawColor( Color( 255, 0, 0, 255 ) )
				surface.DrawOutlinedRect(0,0,w,h)
			end*/
			/*local timer = vgui.Create("DPanel", timeText)
			timer:SetSize(256, 256)
			timer.Paint = function(self, w, h)
				draw.SimpleText(actionTime, "VRText", 0, 0, Color(255, 170, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end*/
			if VRUtilIsMenuOpen("timer") then
				VRUtilMenuClose("timer")
			end
			timeText:SetPos(0, 0)
			VRUtilMenuOpen("timer", 32, 32, timeText, 1, Vector(6,6,6), Angle(0,-90,50), 0.6, false, nil)
			VRUtilMenuRenderPanel("timer")
		end
	end

	if timer.Exists("TimerLower") then timer.Destroy("TimerLower") end
	timer.Create("TimerLower", 1, actionTime, function()
		actionTime = actionTime - 1
		if g_VR and g_VR.active then
			VRUtilMenuRenderPanel("timer")
		end
		hook.Run("TGMTimerTick", actionTime)

		if actionTime <= 0 or not actionTime then
			if timeText then
				if g_VR and g_VR.active then
					VRUtilMenuClose("timer")
				end
				timeText:Remove()
				timeText = nil
			end
			hook.Run("TGMTimerEnd")
			timer.Destroy("TimerLower")
		end
	end)
end)

net.Receive("ItsAMystery", function()
	timer.Create("Mystery", 0, 0, function()
		LocalPlayer():SetEyeAngles(Angle(0, SysTime() * 50 % 360, 0))
	end)
	timer.Simple(ActionDuration, function()
		timer.Destroy("Mystery")
	end)
end)

net.Receive("Instakill", function()
	surface.PlaySound("instakill.mp3")
	local loopsound = PlayLoopingSound("instakill_loop.wav")
	loopsound:PlayEx(0.5, 100)
	timer.Simple(ActionDuration, function()
		loopsound:FadeOut(1)
	end)
end)

net.Receive("Kamikaze", function()
	local ply = net.ReadUInt(8)
	ply = Player(ply)
	ply.Kamikaze = true
	if ply == LocalPlayer() then
		KamikazeVar = true
		LocalPlayer():ChatPrint("You are the Kamikaze! Kill " .. math.Clamp(#player.GetAll() / 5, 1, 200) .." or more players and you will be revived!")
		timer.Simple(ActionDuration, function()
			KamikazeVar = false
		end)
	end
	timer.Simple(ActionDuration, function()
		ply.Kamikaze = false
	end)
end)

net.Receive("MobaMode", function()
	MobaMode = true
	timer.Simple(ActionDuration, function()
		MobaMode = false
	end)
end)

local function PlayBossMusic()
	local music_duration = 1
	if timer.Exists("BossMusic") then timer.Remove("BossMusic") end
	timer.Create("BossMusic", music_duration, 0, function()
		print("boss music change")
		math.randomseed(os.time())
		Boss_CurrentMusic = boss_music[GetPseudoRandomNumber(#boss_music)]
		PrintTable(Boss_CurrentMusic)
		sound.PlayFile("sound/"..Boss_CurrentMusic.song, "", function(audio_channel, err, errorName)
			if err then
				ErrorNoHalt(err)
				print(errorName)
			end
			MusicChannel = audio_channel
		end)
		music_duration = Boss_CurrentMusic.duration
		timer.Adjust("BossMusic", music_duration)
	end)
end

net.Receive("BossMode", function()
	local bool = net.ReadBool()
	print("do this be runnin")
	if bool then
		PlayBossMusic()
	else
		print("Stopping " .. Boss_CurrentMusic.song)
		//LocalPlayer():StopSound(Boss_CurrentMusic.song)
		MusicChannel:Stop()
		timer.Destroy("BossMusic")
	end
end)

net.Receive("BossPlayer", function()
	local bool = net.ReadBool()
	if bool then
		IsBoss = true
	else
		IsBoss = false
	end
end)

net.Receive("RandomOverlay", function()
	math.randomseed(os.time())
	local rand = math.random(#pp_effects)
	RandomOverlay = true
	if g_VR then
		RndRefract = math.Rand(0.01, 0.1)
	else
		RndRefract = math.Rand(0.3, 0.8)
	end
	RndOverlay = pp_effects[rand]
	timer.Simple(ActionDuration, function()
		RandomOverlay = false
	end)
end)

net.Receive("RandomTexturize", function()
	math.randomseed(os.time())
	RandomTexturize = true
	TxtEffect = txt_effects[math.random(#txt_effects)]
	timer.Simple(ActionDuration, function()
		RandomTexturize = false
	end)
end)

net.Receive("Nearsightedness", function()
	RunConsoleCommand("pp_dof_initlength", "9.00")
	RunConsoleCommand("pp_dof_spacing", "8.00")
	DOF_Start()
	timer.Simple(ActionDuration, function()
		DOF_Kill()
	end)
end)

net.Receive("3DMode", function()
	if g_VR then print("Cannot do 3Dmode effect in VR!") return end
	RunConsoleCommand("pp_stereoscopy", "1")
	timer.Simple(ActionDuration, function()
		RunConsoleCommand("pp_stereoscopy", "0")
	end)
end)

net.Receive("MegaBloom", function()
	MegaBloom = true
	timer.Simple(ActionDuration, function()
		MegaBloom = false
	end)
end)