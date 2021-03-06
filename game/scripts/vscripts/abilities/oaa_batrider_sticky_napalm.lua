batrider_sticky_napalm_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_batrider_sticky_napalm_oaa_passive", "abilities/oaa_batrider_sticky_napalm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_batrider_sticky_napalm_oaa_debuff", "abilities/oaa_batrider_sticky_napalm.lua", LUA_MODIFIER_MOTION_NONE)

--[[
function batrider_sticky_napalm_oaa:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_batrider/batrider_stickynapalm_impact.vpcf", context)
  PrecacheResource("particle", "particles/status_fx/status_effect_stickynapalm.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_batrider/batrider_napalm_damage_debuff.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_batrider.vsndevts", context)
end
]]

function batrider_sticky_napalm_oaa:GetIntrinsicModifierName()
  return "modifier_batrider_sticky_napalm_oaa_passive"
end

function batrider_sticky_napalm_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function batrider_sticky_napalm_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()
  local radius = self:GetSpecialValueFor("radius")

  -- Sounds
  caster:EmitSound("Hero_Batrider.StickyNapalm.Cast")
  EmitSoundOnLocationWithCaster(point, "Hero_Batrider.StickyNapalm.Impact", caster)

  -- Particle
  local napalm_impact_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_impact.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(napalm_impact_particle, 0, point)
  ParticleManager:SetParticleControl(napalm_impact_particle, 1, Vector(radius, 0, 0))
  ParticleManager:SetParticleControl(napalm_impact_particle, 2, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(napalm_impact_particle)

  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    point,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local duration = self:GetSpecialValueFor("duration")
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      -- Take status resistance of the enemy and calculate actual duration
      local actual_duration = enemy:GetValueChangedByStatusResistance(duration)
      enemy:AddNewModifier(caster, self, "modifier_batrider_sticky_napalm_oaa_debuff", {duration = actual_duration})
    end
  end

  -- "Provides 450 radius flying vision at the targeted point upon cast for 2 seconds."
  AddFOWViewer(caster:GetTeamNumber(), point, radius, 2, false)
end

function batrider_sticky_napalm_oaa:OnUnStolen()
  local caster = self:GetCaster()
  local passive = caster:FindModifierByName("modifier_batrider_sticky_napalm_oaa_passive")
  if passive then
    caster:RemoveModifierByName("modifier_batrider_sticky_napalm_oaa_passive")
  end
end

---------------------------------------------------------------------------------------------------

modifier_batrider_sticky_napalm_oaa_passive = class(ModifierBaseClass)

function modifier_batrider_sticky_napalm_oaa_passive:IsHidden()
  return true
end

function modifier_batrider_sticky_napalm_oaa_passive:IsDebuff()
  return false
end

function modifier_batrider_sticky_napalm_oaa_passive:IsPurgable()
  return false
end

function modifier_batrider_sticky_napalm_oaa_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
    --MODIFIER_PROPERTY_DISABLE_TURNING,
    MODIFIER_EVENT_ON_ORDER,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }

  return funcs
end

function modifier_batrider_sticky_napalm_oaa_passive:GetModifierIgnoreCastAngle()
  if not IsServer() or self.bActive == false then
    return
  end
  return 1
end

--[[
function modifier_batrider_sticky_napalm_oaa_passive:GetModifierDisableTurning()
  if not IsServer() or self.bActive == false then
    return
  end
  return 1
end
]]

function modifier_batrider_sticky_napalm_oaa_passive:OnOrder(event)
  local parent = self:GetParent()
  if not IsServer() or event.unit ~= parent then
    return
  end

  if event.ability == self:GetAbility() and event.order_type == DOTA_UNIT_ORDER_CAST_POSITION then
    self.bActive = true
  else
    self.bActive = false
  end
end

function modifier_batrider_sticky_napalm_oaa_passive:OnTakeDamage(event)
  if not IsServer() then
    return
  end

  local attacker = event.attacker
  local damaged_unit = event.unit
  local caster = self:GetParent() or self:GetCaster()
  local ability = self:GetAbility()

  -- Continue only if the caster/parent is the attacker
  if attacker ~= caster then
    return
  end

  -- If caster or ability don't exist -> don't continue
  if not caster or caster:IsNull() or not ability or ability:IsNull() then
    return
  end

  -- Don't continue if attacker is deleted or he is about to be deleted
  if not attacker or attacker:IsNull() then
    return
  end

  -- Don't continue if attacker is an illusion
  if attacker:IsIllusion() then
    return
  end

  -- Don't continue if damaged_unit is deleted or he is about to be deleted
  if not damaged_unit or damaged_unit:IsNull() then
    return
  end

  -- Don't continue if self damage
  if damaged_unit == attacker then
    return
  end

  -- Check if entity is an item, rune or something weird
  if damaged_unit.GetUnitName == nil then
    return
  end

  -- Don't affect buildings, wards and invulnerable units.
  if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
    return
  end

  -- Don't continue if damaged_unit doesn't have sticky napalm debuff
  if not damaged_unit:HasModifier("modifier_batrider_sticky_napalm_oaa_debuff") then
    return
  end

  local inflictor = event.inflictor
  local non_trigger_inflictors = {
    ["batrider_sticky_napalm"] = true,
    ["batrider_sticky_napalm_oaa"] = true,
    ["item_orb_of_venom"] = true,
    ["item_orb_of_corrosion"] = true,
    ["item_radiance"] = true,
    ["item_radiance_2"] = true,
    ["item_radiance_3"] = true,
    ["item_radiance_4"] = true,
    ["item_radiance_5"] = true,
    ["item_urn_of_shadows"] = true,
    ["item_spirit_vessel"] = true,
    ["item_spirit_vessel_2"] = true,
    ["item_spirit_vessel_3"] = true,
    ["item_spirit_vessel_4"] = true,
    ["item_spirit_vessel_5"] = true,
    ["item_cloak_of_flames"] = true,
    ["item_trumps_fists"] = true,
    ["item_trumps_fists_2"] = true,
    ["item_silver_staff"] = true,
    ["item_silver_staff_2"] = true,
  }

  -- For debugging
  --if inflictor then
    --print("Inflictor is: "..inflictor:GetName())
  --end

  if inflictor and non_trigger_inflictors[inflictor:GetName()] then
    return
  end

  -- Ignore damage that has the no-reflect flag
  if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
    return
  end

  local debuff = damaged_unit:FindModifierByNameAndCaster("modifier_batrider_sticky_napalm_oaa_debuff", caster)

  -- Damaged unit has the debuff but not the same caster
  if not debuff or debuff:IsNull() then
    return
  end

  local stack_count = debuff:GetStackCount()

  local bonus_damage = ability:GetLevelSpecialValueFor("damage_per_stack", ability:GetLevel()-1)

  local talent = caster:FindAbilityByName("special_bonus_unique_batrider_4")
  if talent and talent:GetLevel() > 0 then
    bonus_damage = bonus_damage + talent:GetSpecialValueFor("value")
  end

  local damage_non_ancient_creeps = ability:GetSpecialValueFor("damage_creeps")
  local damage_ancients = ability:GetSpecialValueFor("damage_ancients")
  local damage_bosses = ability:GetSpecialValueFor("damage_bosses")

  if not damaged_unit:IsHero() then
    if damaged_unit:IsAncient() then
      if damaged_unit:IsOAABoss() then
        bonus_damage = bonus_damage * damage_bosses * 0.01
      else
        bonus_damage = bonus_damage * damage_ancients * 0.01
      end
    else
      bonus_damage = bonus_damage * damage_non_ancient_creeps * 0.01
    end
  end

  -- Damage particle
  local damage_debuff_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_napalm_damage_debuff.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:ReleaseParticleIndex(damage_debuff_particle)

  -- Apply damage
  local damage_table = {}
  damage_table.victim = damaged_unit
  damage_table.damage_type = DAMAGE_TYPE_MAGICAL
  damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE
  damage_table.attacker = caster
  damage_table.ability = ability
  damage_table.damage = bonus_damage * stack_count

  ApplyDamage(damage_table)
end

---------------------------------------------------------------------------------------------------

modifier_batrider_sticky_napalm_oaa_debuff = class(ModifierBaseClass)

function modifier_batrider_sticky_napalm_oaa_debuff:IsHidden()
  return false
end

function modifier_batrider_sticky_napalm_oaa_debuff:IsDebuff()
  return true
end

function modifier_batrider_sticky_napalm_oaa_debuff:IsPurgable()
  return true
end

function modifier_batrider_sticky_napalm_oaa_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed_slow = ability:GetSpecialValueFor("movement_speed_pct")
    self.turn_speed_slow = ability:GetSpecialValueFor("turn_rate_pct")
    self.max_stacks = ability:GetSpecialValueFor("max_stacks")
  else
    self.move_speed_slow = -2
    self.turn_speed_slow = -10
    self.max_stacks = 10
  end

  if IsServer() then
    self:SetStackCount(1)
  end

  self.stack_particle = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_batrider/batrider_stickynapalm_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber())
  ParticleManager:SetParticleControl(self.stack_particle, 1, Vector(math.floor(self:GetStackCount() / 10), self:GetStackCount() % 10, 0))
  self:AddParticle(self.stack_particle, false, false, -1, false, false)
end

function modifier_batrider_sticky_napalm_oaa_debuff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed_slow = ability:GetSpecialValueFor("movement_speed_pct")
    self.turn_speed_slow = ability:GetSpecialValueFor("turn_rate_pct")
    self.max_stacks = ability:GetSpecialValueFor("max_stacks")
  else
    self.move_speed_slow = -2
    self.turn_speed_slow = -10
    self.max_stacks = 10
  end

  if IsServer() and self:GetStackCount() < self.max_stacks then
    self:IncrementStackCount()
  end

  if self.stack_particle then
    ParticleManager:SetParticleControl(self.stack_particle, 1, Vector(math.floor(self:GetStackCount() / 10), self:GetStackCount() % 10, 0))
  end
end

function modifier_batrider_sticky_napalm_oaa_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
  }
  return funcs
end

function modifier_batrider_sticky_napalm_oaa_debuff:GetModifierMoveSpeedBonus_Percentage()
  return math.min(self.max_stacks, self:GetStackCount()) * self.move_speed_slow
end

function modifier_batrider_sticky_napalm_oaa_debuff:GetModifierTurnRate_Percentage()
  return self.turn_speed_slow
end

function modifier_batrider_sticky_napalm_oaa_debuff:GetStatusEffectName()
  return "particles/status_fx/status_effect_stickynapalm.vpcf"
end

function modifier_batrider_sticky_napalm_oaa_debuff:StatusEffectPriority()
  return MODIFIER_PRIORITY_LOW
end
