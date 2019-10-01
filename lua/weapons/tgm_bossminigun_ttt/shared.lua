SWEP.DrawCrosshair = false
SWEP.Weight = 45
SWEP.ViewModel = "models/minigun_model/weapons/c_minigun.mdl"
SWEP.WorldModel = "models/minigun_model/weapons/w_minigun.mdl"
SWEP.HoldType = "shotgun"
SWEP.ViewModelFOV =	64
SWEP.Slot = 2
SWEP.Purpose = ""
SWEP.AutoSwitchTo = true
SWEP.Contact = "no"
SWEP.Author = "nonhuman, edited by mineturtle"
SWEP.FiresUnderwater = false
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ReloadSound = Sound("weapons/minigun1/New3/minigunreload.wav")
SWEP.SlotPos = 0
SWEP.Instructions = "shoot"
SWEP.AutoSwitchFrom = false
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_ROLE
SWEP.Icon = "hud/killicons/minigun_swep"
SWEP.Category = "Other"
SWEP.DrawAmmo = true
SWEP.PrintName = "Minigun"
SWEP.UseHands = true
SWEP.HeadshotMultiplier = 1

if CLIENT then
	killicon.Add("weapon_mini_gun_v3", "HUD/killicons/minigun_swep", Color( 255, 80, 0, 255 ));
end
if SERVER then
	resource.AddFile("materials/hud/killicons/minigun_swep.vmt")
end

function SWEP:Deploy()
	self:SetWeaponHoldType( self.HoldType )
	self.Weapon:EmitSound( "weapons/minigun1/New3/drawminigun.wav" )
      return true
end

SWEP.Primary.NumberofShots = 12
SWEP.Primary.Ammo = "none"
SWEP.Primary.Spread = 1
SWEP.Primary.ClipSize = -1
SWEP.Primary.Force = 20
SWEP.Primary.Damage = 1
SWEP.Primary.Delay = 0.06
SWEP.Primary.Recoil = 0.05
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.TakeAmmo = 1
SWEP.Primary.Sound = Sound("Minigun.Shoot")

SWEP.Secondary.Automatic = false
SWEP.Secondary.Force = 0
SWEP.Secondary.Recoil = 0
SWEP.Secondary.Damage = 0
SWEP.Secondary.Ammo = ""
SWEP.Secondary.NumberofShots = 0
SWEP.Secondary.Spread = 0
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Delay = 1
SWEP.Secondary.Sound = ""
SWEP.Secondary.TakeAmmo = 0
SWEP.Secondary.ClipSize = -1

sound.Add({
	name = "Minigun.Start",

	channel = CHAN_WEAPON,
	volume = 1.0,
	CompatibilityAttenuation = 1.0,
	pitch = 100,

	sound = "weapons/minigun1/New3/minigunstart.wav"
})

sound.Add({
	name = "Minigun.Shoot",

	channel = CHAN_WEAPON,
	volume = 1.0,
	CompatibilityAttenuation = 1.0,
	pitch = 150,

	sound = "weapons/minigun1/New3/minigunshoot.wav"
})

sound.Add({
	name = "Minigun.Spin",

	channel = CHAN_STATIC,
	volume = 1.0,
	CompatibilityAttenuation = 1.0,
	pitch = 100,

	sound = "weapons/minigun1/New3/minigunspin.wav"
})

sound.Add({
	name = "Minigun.Stop",

	channel = CHAN_WEAPON,
	volume = 1.0,
	CompatibilityAttenuation = 1.0,
	pitch = 100,

	sound = "weapons/minigun1/New3/minigunstop.wav"
})

sound.Add({
	name = "Minigun.Reload",

	channel = CHAN_STATIC,
	volume = 1.0,
	CompatibilityAttenuation = 1.0,
	pitch = 100,

	sound = "weapons/minigun1/New3/minigunreload.wav"
})

function SWEP:Think()
	self:SetWeaponHoldType( self.HoldType )

	if 	self.Owner:KeyPressed(IN_ATTACK) then 
		
		local vm = self.Owner:GetViewModel()
		vm:SendViewModelMatchingSequence( vm:LookupSequence( "fire04" ) )	
	    self:SetNextPrimaryFire(CurTime() + 0.7)
		self:SetNextSecondaryFire(CurTime() + 0.7)
		self.Weapon:EmitSound(Sound("Minigun.Start"))
		self.Owner:ConCommand( "+walk" )
		self.Owner:ConCommand( "-speed" )
		if CLIENT then return end
	end
	

	if 	self.Owner:KeyReleased(IN_ATTACK) then
		local vm = self.Owner:GetViewModel()	
		self.Weapon:StopSound( "weapons/minigun1/New3/minigunspin.wav" )
		self.Weapon:EmitSound(Sound("Minigun.Stop"))
		timer.Simple( 0.1, function() self.Owner:ConCommand( "-walk" ) end );
		if CLIENT then return end
	end
end 


function SWEP:Idle()
	self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
end

function SWEP:Initialize()
	self:SetWeaponHoldType( "physgun" )
end

function SWEP:PrimaryAttack()
	randompitch = math.Rand(90, 130)
	
	local bullet = {}
		bullet.Num = self.Primary.NumberofShots
		bullet.Src = self.Owner:GetShootPos()
		bullet.Dir = self.Owner:GetAimVector()
		bullet.Spread = Vector( self.Primary.Spread * 0.1 , self.Primary.Spread * 0.1, 0)
		bullet.Tracer	= 1
		bullet.TracerName = "Tracer" 
		bullet.Force = self.Primary.Force
		bullet.Damage = self.Primary.Damage
		bullet.AmmoType = self.Primary.Ammo	
	local rnda = self.Primary.Recoil * 1
	local rndb = self.Primary.Recoil * math.random(-10, 10)
	self.Owner:ViewPunch( Angle( 0.01, 0, 0 ) )
	self:ShootEffects()
	self.Owner:FireBullets( bullet )
	self.Weapon:EmitSound(Sound(self.Primary.Sound))
	self.Owner:ViewPunch( Angle( rnda,rndb,rnda ) )
	self:TakePrimaryAmmo(self.Primary.TakeAmmo)
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	
		self.Owner:ConCommand( "-speed" )
		self.Owner:ConCommand( "+walk" )
		
end

function SWEP:Holster()
		self.Owner:ConCommand( "-speed" )
		self.Owner:ConCommand( "-walk" )
		self.Weapon:StopSound( "weapons/minigun1/New3/minigunshoot.wav" )
			return true
end

function SWEP:Reload()
	if ( self:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
		self:DefaultReload( ACT_VM_RELOAD )		
		self.Owner:ConCommand( "-attack" )
		self.Owner:ConCommand( "-speed" )
		self.Owner:ConCommand( "-walk" )
		self.Weapon:EmitSound(Sound("Minigun.Reload"))
		self.Weapon:StopSound( "weapons/minigun1/New3/minigunshoot.wav" )
    	local AnimationTime = self.Owner:GetViewModel():SequenceDuration()
    	self.ReloadingTime = CurTime() + 1
    	self:SetNextPrimaryFire(CurTime() + 1)
		self:SetNextSecondaryFire(CurTime() + 1)
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:DrawHUD()
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	surface.SetDrawColor(200, 255, 0, 255)
	local gap = 20
	local length = gap + 20
	surface.DrawLine(x - length, y, x - gap, y)
	surface.DrawLine(x + length, y, x + gap, y)
	surface.DrawLine(x, y - length, x, y - gap)
	surface.DrawLine(x, y + length, x, y + gap)
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
   return self.HeadshotMultiplier
end