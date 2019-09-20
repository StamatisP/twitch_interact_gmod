print("client load!")
AddCSLuaFile()
CreateClientConVar("tgm_chat", "0", true, true, "If you get Twitch chat printed to your chat.")
local voting_time = false
local isDoubleVote = false

local ScreenFuck = false

local SilentHill = false
local Fog_End = 5600
local Fog_Density = 0

local Paranoia = false

local votes = {}

do // precache here
	/*util.PrecacheSound( "the_world_time_stop.mp3" )
	util.PrecacheSound( "the_world_time_start.mp3" )
	if file.Exists("sound/spy_cloak.wav", "GAME") then
		util.PrecacheSound("spy_cloak.wav")
		util.PrecacheSound("spy_uncloak.wav")
	else
		util.PrecacheSound("invis_on.mp3")
		util.PrecacheSound("invis_off.mp3")
	end*/

	for k, v in pairs(file.Find("sound/*", "GAME")) do
		util.PrecacheSound(v)
	end
end

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

local f
local label1, label2, label3, label4
local progbar1, progbar2, progbar3, progbar4

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

net.Receive("PrintTwitchChat", function()
	local user = net.ReadString()
	local message = net.ReadString()
	math.randomseed(string.byte(user))
	chat.AddText(TwitchColors[math.random(#TwitchColors)], user .. ": ", Color(255, 255, 255), message)
end)

hook.Add("OnPlayerChat", "check_tgm_chat", function(ply, text, teamchat, isdead)
	if text == "!chat" then
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
	print("REPLACE VALUES TIME")
	local maxVotes = 0
	for k, v in ipairs(votes) do
		maxVotes = maxVotes + v.value
	end
	if isDoubleVote then
		label1:SetText2(PrettyFuncs[votes[1].name] .. " + " .. PrettyFuncs[votes[1].name2] .. " (!" .. votes[1].name .. ")")
		label2:SetText2(PrettyFuncs[votes[2].name] .. " + " .. PrettyFuncs[votes[2].name2] .. " (!" .. votes[2].name .. ")")
		label3:SetText2(PrettyFuncs[votes[3].name] .. " + " .. PrettyFuncs[votes[3].name2] .. " (!" .. votes[3].name .. ")")
		label4:SetText2(PrettyFuncs[votes[4].name] .. " + " .. PrettyFuncs[votes[4].name2] .. " (!" .. votes[4].name .. ")")
	else
		label1:SetText2(PrettyFuncs[votes[1].name] .. " (!" .. votes[1].name .. ")")
		label2:SetText2(PrettyFuncs[votes[2].name] .. " (!" .. votes[2].name .. ")")
		label3:SetText2(PrettyFuncs[votes[3].name] .. " (!" .. votes[3].name .. ")")
		label4:SetText2(PrettyFuncs[votes[4].name] .. " (!" .. votes[4].name .. ")")
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

net.Receive("FuckWithScreen", function()
	ScreenFuck = true
	print("this be runnin")
	timer.Simple(10, function()
		ScreenFuck = false
	end)
end)

net.Receive("the_world_time_stop.PlaySound", function()
    surface.PlaySound("the_world_time_stop.mp3")
end)
net.Receive("the_world_time_start.PlaySound", function()
    surface.PlaySound("the_world_time_start.mp3")
end)

local function TGMRender()
	if ScreenFuck then
		//print("please")
		DrawColorModify(deepfryTab)
		DrawSobel(0.5)
		DrawSharpen(3, 3)
	elseif SilentHill then
		DrawMaterialOverlay( "overlays/vignette01", 1 )
	elseif Paranoia then
		DrawColorModify(paranoiaTab)
		DrawSharpen(1.3, 1.3)
		DrawMaterialOverlay( "overlays/vignette01", 1 )
	end
end

hook.Add("RenderScreenspaceEffects", "TGMRender", TGMRender)

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
		render.FogMaxDensity( 1 )
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
		render.FogMaxDensity( 1 )
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

net.Receive("SilentHill", function()
	SilentHill = true
	LocalPlayer():ChatPrint("The fog is rolling in...")
	timer.Create("fog_end_lerp", 0.05, 0, function()
		if Fog_End <= 280 then
			timer.Destroy("fog_end_lerp")
			return
		end
		Fog_End = math.Approach(Fog_End, 280, -140)
		Fog_Density = math.Approach(Fog_Density, 0.99, 0.025)
	end)
	timer.Simple(15, function()
		LocalPlayer():ChatPrint("It's finally clearing up.")
		timer.Create("fog_end_lerp_2", 0.05, 0, function()
			if Fog_End >= 5600 then
				timer.Destroy("fog_end_lerp_2")
				SilentHill = false
				return
			end
			Fog_End = math.Approach(Fog_End, 5600, 140)
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
	local rndvo = math.random(1, 4)
	local rndstart = math.random(1, 2)
	local rndloop = math.random(1, 5)
	local loopsnd = CreateSound(LocalPlayer(), "paranoia_loop_"..rndloop..".wav")
	surface.PlaySound("paranoia_vo_"..rndvo..".mp3")
	surface.PlaySound("paranoia_start_"..rndstart..".wav")
	loopsnd:PlayEx(0.8, 100)
	timer.Create("fog_end_lerp_paranoia", 0.05, 0, function()
		print(Fog_End)
		if Fog_End <= 280 then
			LocalPlayer():SetDSP(31, false)
			loopsnd:SetDSP(0)
			timer.Destroy("fog_end_lerp_paranoia")
			return
		end
		Fog_End = math.Approach(Fog_End, 280, -70)
	end)
	timer.Simple(15, function()
		timer.Create("fog_end_lerp_2_paranoia", 0.05, 0, function()
			if Fog_End >= 5600 then
				loopsnd:FadeOut(1)
				timer.Destroy("fog_end_lerp_2_paranoia")
				LocalPlayer():SetDSP(0, false)
				Paranoia = false
				return
			end
			Fog_End = math.Approach(Fog_End, 5600, 140)
		end)
	end)
end)