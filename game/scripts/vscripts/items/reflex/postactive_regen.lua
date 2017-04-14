LinkLuaModifier( "modifier_item_postactive_regen", "items/reflex/postactive_regen.lua", LUA_MODIFIER_MOTION_NONE )

item_postactive_3c = class({})

function item_postactive_3c:ResetToggleOnRespawn()
  return true
end

function item_postactive_3c:OnToggle(keys)
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, 'modifier_item_postactive_regen', {
    duration = self:GetSpecialValueFor( "duration" )
  })

  -- important else you can use while on CD every other time
  if self:GetToggleState() then
    self:ToggleAbility()
  end

  self:StartCooldown(self:GetCooldownTime())

  return false
end

modifier_item_postactive_regen = class({})

function modifier_item_postactive_regen:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_item_postactive_regen:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor( "bonus_health_regen" )
end
