LinkLuaModifier("modifier_boss_swiper_anti_stun", "abilities/swiper/boss_swiper_swipe.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_swiper_backswipe_base = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:DebugRange(caster, range)
	for i=1,8 do
		local point = caster:GetAbsOrigin() + (caster:GetForwardVector() * range)--self:PointOnCircle(range, 360 / 16 * i)
		DebugDrawSphere(RotatePosition(caster:GetAbsOrigin(), QAngle(0,(360 / 16 * (-i + 0.5)) + 90,0), point), Vector(255,0,0), 255, 32, true, self:GetCastPoint())
	end
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:FindUnitsInCone(position, coneDirection, coneLength, coneWidth, teamNumber, teamFilter, typeFilter, flagFilter, order)
	local units = FindUnitsInRadius(teamNumber, position, nil, coneLength, teamFilter, typeFilter, flagFilter, order, false)

	coneDirection = (coneDirection * Vector(1,1,0)):Normalized()

	local output = {}
	local cone = math.cos(coneWidth/2)

	for _, unit in pairs(units) do
		local direction = ((unit:GetAbsOrigin() - position) * Vector(1,1,0)):Normalized()
		if direction:Dot(coneDirection) >= cone then
			table.insert(output, unit)
		end
	end

	return output
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:PointOnCircle(radius, angle)
	local x = radius * math.cos(angle * math.pi / 180)
	local y = radius * math.sin(angle * math.pi / 180)
	return Vector(x,y,0)
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:GetPlaybackRateOverride()
	return 0.35
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local caster_loc = caster:GetAbsOrigin()
    local range = self:GetCastRange(caster_loc, caster)
    local hit = {}

    caster:AddNewModifier(caster, self, "modifier_boss_swiper_anti_stun", {duration = self:GetCastPoint()})

    self:DebugRange(caster, range)

    local delay = self:GetSpecialValueFor("delay") --self:GetCastPoint()

    local position2 = caster_loc + (caster:GetForwardVector() * range)
    local position1 = RotatePosition(caster_loc, QAngle(0,45,0), position2)
    local position3 = RotatePosition(caster_loc, QAngle(0,-45,0), position2)
    local forward1 = (position1 - caster_loc):Normalized()
    local forward3 = (position3 - caster_loc):Normalized()
    local width = (position2 - position1):Length2D() / 2

    -- Warning particle
    local FX = ParticleManager:CreateParticle("particles/warning/warning_particle_cone.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(FX, 1, GetGroundPosition(caster_loc, nil)
    ParticleManager:SetParticleControl(FX, 2, GetGroundPosition(position2, nil)
    ParticleManager:SetParticleControl(FX, 3, Vector(3*width, 100, 3*width))
    ParticleManager:SetParticleControl(FX, 4, Vector(255, 0, 0))
    ParticleManager:ReleaseParticleIndex(FX)

    -- Hit particle
    Timers:CreateTimer(delay, function()
      local swipe = ParticleManager:CreateParticle(self.particleName, PATTACH_CUSTOMORIGIN, caster)
      ParticleManager:SetParticleControl(swipe, 0, caster_loc + (caster:GetForwardVector() * 50) + Vector(0,0,100))
      ParticleManager:SetParticleControl(swipe, 1, caster_loc + (caster:GetForwardVector() * 100) + Vector(0,0,100))
      ParticleManager:SetParticleControl(swipe, 2, Vector(1.25,0,0))
      ParticleManager:SetParticleControl(swipe, 3, Vector(0.8,0,0))
      ParticleManager:ReleaseParticleIndex(swipe)
    end)

		local directions = {}
		table.insert(directions, forward1)
		table.insert(directions, caster:GetForwardVector())
		table.insert(directions, forward3)

		local function Impact(v)
			v:EmitSound("Hero_Juggernaut.BladeDance")

			local impact = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_ti6_immortal/pudge_meathook_witness_impact_ti6.vpcf", PATTACH_POINT_FOLLOW, v)
			ParticleManager:ReleaseParticleIndex(impact)
			local damageTable = {
				victim = v,
				attacker = caster,
				damage = self:GetSpecialValueFor("damage"),
				damage_type = self:GetAbilityDamageType(),
				ability = self
			}
			ApplyDamage(damageTable)
		end

		local isFront = string.match(self:GetName(), "frontswipe")
		local modifier = 0
		if isFront then
			modifier = 4
		end

		for k, direction in pairs(directions) do
			Timers:CreateTimer(delay + (delay * math.abs(k - modifier))/6, function()
				local units = self:FindUnitsInCone(
					caster_loc,
					direction,
					range,
					width,
					caster:GetTeamNumber(),
					DOTA_UNIT_TARGET_TEAM_ENEMY,
					DOTA_UNIT_TARGET_ALL,
					DOTA_UNIT_TARGET_FLAG_NONE,
					FIND_CLOSEST
				)
				for __,target in pairs(units) do
					if not hit[target:entindex()] then
						hit[target:entindex()] = true
						Impact(target)
					end
				end
			end)
		end
	end
	return true
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local range = self:GetCastRange(caster:GetAbsOrigin(), caster)
	end
end

------------------------------------------------------------------------------------

modifier_boss_swiper_anti_stun = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_swiper_anti_stun:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_anti_stun:IsPurgable()
	return false
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_anti_stun:CheckState()
	local state =
	{
		[MODIFIER_STATE_STUNNED] = false
	}

	return state
end
