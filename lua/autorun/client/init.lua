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

local LoadedSounds = {}

local votes = {}
local ActionDuration = 15
local actionTime = actionTime or 0
local timeText

local f
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

/* HOOKS */

local function TGMRender()
	if ScreenFuck then
		//print("please")
		DrawColorModify(deepfryTab)
		DrawSobel(0.5)
		DrawSharpen(3, 3)
	elseif SilentHill then
		DrawColorModify(silenthillTab)
		DrawMaterialOverlay( "overlays/vignette01", 1 )
	elseif Paranoia then
		DrawColorModify(paranoiaTab)
		DrawSharpen(1.3, 1.3)
		DrawMaterialOverlay( "overlays/vignette01", 1 )
	elseif WhosWho then
		DrawColorModify(whoswhoTab)
		DrawMaterialOverlay("overlays/vignette01", 1)
	elseif KamikazeVar then
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
			end

			cam.IgnoreZ(false)
			render.SuppressEngineLighting(false)
		cam.End3D()
	end
end

hook.Add("RenderScreenspaceEffects", "TGMRender", TGMRender)

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
	local eyetrace = ply:GetEyeTrace()
	if MobaMode then
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

vgui.Register("FuncLabel", FuncLabel, "DLabel")

local function VoteDerma(isDoubleVote)
	if not isDoubleVote then isDoubleVote = false end
	f = vgui.Create("DFrame")
	if isDoubleVote then
		f:SetSize(750, 350)
	else
		f:SetSize(500, 350)
	end
	local frameWidth, frameHeight = f:GetSize()
	f:SetTitle("Vote Menu")
	f:SetPos(ScrW() - frameWidth, 0)
	//f:CenterVertical(0.5)
	f:ShowCloseButton(false)
	f.Paint = function(s, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(60, 60, 60, 100))
	end

	label1 = vgui.Create("FuncLabel", f)
	label1:SetPos(15, 30)

	progbar1 = vgui.Create("DProgress", f)
	progbar1:SetPos(25, 60)
	progbar1:SetSize(frameWidth - 50, 40)

	label2 = vgui.Create("FuncLabel", f)
	label2:SetPos(15, 110)

	progbar2 = vgui.Create("DProgress", f)
	progbar2:SetPos(25, 140)
	progbar2:SetSize(frameWidth - 50, 40)

	label3 = vgui.Create("FuncLabel", f)
	label3:SetPos(15, 190)

	progbar3 = vgui.Create("DProgress", f)
	progbar3:SetPos(25, 220)
	progbar3:SetSize(frameWidth - 50, 40)

	label4 = vgui.Create("FuncLabel", f)
	label4:SetPos(15, 270)

	progbar4 = vgui.Create("DProgress", f)
	progbar4:SetPos(25, 300)
	progbar4:SetSize(frameWidth - 50, 40)
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
	local maxVotes = 0
	for k, v in ipairs(votes) do
		maxVotes = maxVotes + v.value
	end
	if isDoubleVote then
		label1:SetText2( (PrettyFuncs[votes[1].name] or votes[1].name) .. " + " .. (PrettyFuncs[votes[1].name2] or votes[1].name2) .. " (!" .. votes[1].name .. ")")
		label2:SetText2( (PrettyFuncs[votes[2].name] or votes[2].name) .. " + " .. (PrettyFuncs[votes[2].name2] or votes[2].name2) .. " (!" .. votes[2].name .. ")")
		label3:SetText2( (PrettyFuncs[votes[3].name] or votes[3].name) .. " + " .. (PrettyFuncs[votes[3].name2] or votes[3].name2) .. " (!" .. votes[3].name .. ")")
		label4:SetText2( (PrettyFuncs[votes[4].name] or votes[4].name) .. " + " .. (PrettyFuncs[votes[4].name2] or votes[4].name2) .. " (!" .. votes[4].name .. ")")
	else
		label1:SetText2( (PrettyFuncs[votes[1].name] or votes[1].name) .. " (!" .. votes[1].name .. ")")
		label2:SetText2( (PrettyFuncs[votes[2].name] or votes[2].name) .. " (!" .. votes[2].name .. ")")
		label3:SetText2( (PrettyFuncs[votes[3].name] or votes[3].name) .. " (!" .. votes[3].name .. ")")
		label4:SetText2( (PrettyFuncs[votes[4].name] or votes[4].name) .. " (!" .. votes[4].name .. ")")
	end

	progbar1:SetFraction(votes[1].value / maxVotes)
	progbar2:SetFraction(votes[2].value / maxVotes)
	progbar3:SetFraction(votes[3].value / maxVotes)
	progbar4:SetFraction(votes[4].value / maxVotes)
	//PrintTable(votes)
end)

net.Receive("EndVoting", function()
	f:Close()
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

net.Receive("the_world_time_stop.PlaySound", function()
    surface.PlaySound("the_world_time_stop.mp3")
end)
net.Receive("the_world_time_start.PlaySound", function()
    surface.PlaySound("the_world_time_start.mp3")
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
	local bool = net.ReadBool()
	ThirdPerson = bool
end)

net.Receive("WhosWho", function()
	WhosWho = net.ReadBool()
	local loopsound = PlayLoopingSound("whoswho_loop.wav")
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
		if timeText then
			timeText:Close()
		end
		timer.Destroy("TimerLower")
	end
end)

net.Receive("StartTimer", function()
	actionTime = net.ReadFloat()
	actionTime = actionTime - 1

	local guiScale = ScrW() / 1920
	timeText = vgui.Create("DFrame")
	timeText:SetSize(250, 150)
	timeText:CenterHorizontal()
	timeText:SetPos(timeText:GetPos() + 50 / guiScale, 300 / guiScale)
	timeText:ShowCloseButton(false)
	timeText:SetDraggable(false)
	timeText:SetTitle("")
	timeText.Paint = function(self, w, h)
		draw.SimpleTextOutlined(actionTime, "DermaLarge", 2, 2, Color(255, 170, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0))
	end

	timer.Create("TimerLower", 1, actionTime, function()
		actionTime = actionTime - 1
		if WhosWho then
			whoswhoTab["$pp_colour_colour"] = math.Clamp(actionTime / 30, 0.01, 1)
			whoswhoTab["$pp_colour_brightness"] = Lerp(actionTime / 30, -0.25, 0.18)
		end
		if actionTime <= 0 or not actionTime then
			if timeText then
				timeText:Close()
				timeText = nil
			end
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