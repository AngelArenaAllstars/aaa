black_dragon_dragonhide_aura_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_dragonhide_aura_oaa_applier", "abilities/neutrals/oaa_black_dragon_dragonhide_aura.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_dragonhide_aura_oaa_effect", "abilities/neutrals/oaa_black_dragon_dragonhide_aura.lua", LUA_MODIFIER_MOTION_NONE )

function black_dragon_dragonhide_aura_oaa:GetIntrinsicModifierName()
  return "modifier_dragonhide_aura_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_dragonhide_aura_oaa_applier = class(ModifierBaseClass)

function modifier_dragonhide_aura_oaa_applier:IsHidden()
  return true
end

function modifier_dragonhide_aura_oaa_applier:IsDebuff()
  return false
end

function modifier_dragonhide_aura_oaa_applier:IsPurgable()
  return false
end

function modifier_dragonhide_aura_oaa_applier:IsAura()
  return true
end

function modifier_dragonhide_aura_oaa_applier:GetModifierAura()
  return "modifier_dragonhide_aura_oaa_effect"
end

function modifier_dragonhide_aura_oaa_applier:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_dragonhide_aura_oaa_applier:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_dragonhide_aura_oaa_applier:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_dragonhide_aura_oaa_applier:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_dragonhide_aura_oaa_applier:GetAuraEntityReject(hEntity)
  local caster = self:GetCaster()
  -- Dont provide the aura effect to allies when caster (owner of this aura) cannot be controlled
  if hEntity ~= caster and not caster:IsControllableByAnyPlayer() then
    return true
  end
  return false
end

--------------------------------------------------------------------------------

modifier_dragonhide_aura_oaa_effect = class(ModifierBaseClass)

function modifier_dragonhide_aura_oaa_effect:IsHidden()
  return false
end

function modifier_dragonhide_aura_oaa_effect:IsDebuff()
  return false
end

function modifier_dragonhide_aura_oaa_effect:IsPurgable()
  return false
end

function modifier_dragonhide_aura_oaa_effect:OnCreated()
  self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_dragonhide_aura_oaa_effect:OnRefresh()
  self.bonus_armor = self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_dragonhide_aura_oaa_effect:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_dragonhide_aura_oaa_effect:GetModifierPhysicalArmorBonus()
  return self.bonus_armor
end
