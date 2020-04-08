modifier_boss_magma_mage_volcano_thinker_child = class (ModifierBaseClass)

function modifier_boss_magma_mage_volcano_thinker_child:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano_thinker_child:IsDebuff()
  return false
end

function modifier_boss_magma_mage_volcano_thinker_child:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano_thinker_child:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano_thinker_child:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano_thinker_child:OnCreated(kv)
  if IsServer() then
    self.duration = kv.duration
    self.end_model_scale = self:GetAbility():GetSpecialValueFor("volcano_model_scale")
    self:StartIntervalThink(1/15)
  end
end

function modifier_boss_magma_mage_volcano_thinker_child:OnIntervalThink()
  local scale = self.end_model_scale*(1-self:GetRemainingTime()/self.duration)
  self:GetParent():SetModelScale(scale)
end

function modifier_boss_magma_mage_volcano_thinker_child:CheckState()
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
  return state
end
