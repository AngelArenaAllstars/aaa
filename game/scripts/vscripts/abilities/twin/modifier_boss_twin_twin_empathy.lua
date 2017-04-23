LinkLuaModifier("modifier_boss_twin_twin_empathy", "abilities/twin/boss_twin_twin_empathy.lua", LUA_MODIFIER_MOTION_NONE)

--This may need to be in the abil not the mod
function modifier_boss_twin_twin_empathy_buff:OnCreate()
  local interval = self:GetSpecialValueFor( "heal_timer" )
  mod:StartIntervalThink(interval)
  return true
end

function modifier_boss_twin_twin_empathy_buff:IsHidden()
  return false
end

function modifier_boss_twin_twin_empathy_buff:IsPurgable()
  return false
end

function modifier_item_preemptive_purge:OnIntervalThink()
  if IsServer() then	
  end

  local master = self:GetCaster()
  local twin = self:GetParent()

	if twin:IsAlive() then
	  if twin:GetHealth() < master:GetHealth() then
      twin:SetHealth(master:GetHealth())
    end
    if twin:GetHealth() > master:GetHealth() then
      master:SetHealth(twin:GetHealth()) 
    end
	end
end
