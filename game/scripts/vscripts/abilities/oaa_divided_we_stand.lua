--LinkLuaModifier("modifier_meepo_divided_we_stand_oaa", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_death", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_passive", "abilities/oaa_divided_we_stand.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_bonus_buff", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)

meepo_divided_we_stand_oaa = class(AbilityBaseClass)

function meepo_divided_we_stand_oaa:Spawn()
  self:RefreshMeepos()
end

function meepo_divided_we_stand_oaa:GetIntrinsicModifierName()
  return "modifier_meepo_divided_we_stand_oaa_bonus_buff"
end

function meepo_divided_we_stand_oaa:OnUpgrade()
  local caster = self:GetCaster()

  -- Don't allow illusions to have clones
  if caster:IsIllusion() then
    return
  end

  -- Find Meepo Prime if we are lvling up this ability from the clone
  if caster:IsClone() then
    caster = caster:GetCloneSource()
  end

  --[[
  local PID = caster:GetPlayerOwnerID()
  local mainMeepo = PlayerResource:GetSelectedHeroEntity(PID)

  mainMeepo.meepoList = mainMeepo.meepoList or GetAllMeepos(mainMeepo)

  if caster ~= mainMeepo then
    return nil
  end

  -- Create a clone
  local newMeepo = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
  newMeepo:SetPlayerID(PID)
  newMeepo:SetControllableByPlayer(PID, false)
  newMeepo:SetOwner(caster:GetOwner())
  FindClearSpaceForUnit(newMeepo, caster:GetAbsOrigin(), false)

  -- Preventing dropping and selling items in inventory
  newMeepo:SetHasInventory(false)
  newMeepo:SetCanSellItems(false)

  -- Disabling bounties because clone can die
  newMeepo:SetMaximumGoldBounty(0)
  newMeepo:SetMinimumGoldBounty(0)
  newMeepo:SetDeathXP(0)

  newMeepo:AddNewModifier(caster, self, "modifier_meepo_divided_we_stand_oaa", {})

  table.insert(caster.meepoList, newMeepo)
  ]]

  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("meepo_divided_we_stand")

  if not vanilla_ability then
    return
  end

  -- Max level for vanilla ability is 3 -> check if its 3 already, if yes don't continue
  if vanilla_ability:GetLevel() == 3  or ability_level >= 4 then
    --self:RefreshMeepos()
    return
  end

  vanilla_ability:SetLevel(ability_level)

  --self:RefreshMeepos()
end

function meepo_divided_we_stand_oaa:RefreshMeepos()
  if not IsServer() then
    return
  end
  
  local caster = self:GetCaster()
  -- Find ally heroes everywhere
  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Find all meepos (clones and meepo prime)
  local meepos = {}
  for _, hero in pairs(heroes) do
    if hero and not hero:IsNull() then
      if hero:GetUnitName() == "npc_dota_hero_meepo" and not hero:IsIllusion() then
        table.insert(meepos, hero)
      end
    end
  end

  for _, meepo in pairs(meepos) do
    if meepo and not meepo:IsNull() then
      local buff = meepo:FindModifierByName("modifier_meepo_divided_we_stand_oaa_bonus_buff")
      if buff then
        buff:ForceRefresh()
      else
        meepo:AddNewModifier(caster, self, "modifier_meepo_divided_we_stand_oaa_bonus_buff", {})
      end
	end
  end
end

---------------------------------------------------------------------------------------------------
--[[
modifier_meepo_divided_we_stand_oaa = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa:IsHidden()
	return true
end

function modifier_meepo_divided_we_stand_oaa:IsDebuff()
	return false
end

function modifier_meepo_divided_we_stand_oaa:IsPurgable()
	return false
end

function modifier_meepo_divided_we_stand_oaa:IsPermanent()
  return true
end

function modifier_meepo_divided_we_stand_oaa:DeclareFunctions()
  return {
    --MODIFIER_EVENT_ON_ORDER,
    MODIFIER_EVENT_ON_RESPAWN,
    --MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_meepo_divided_we_stand_oaa:OnCreated(kv)
  if IsServer() then
    self:StartIntervalThink(0.5)
  end
end

function modifier_meepo_divided_we_stand_oaa:OnIntervalThink()
  local meepo = self:GetParent()
  local mainMeepo = self:GetCaster()

  -- Set stats the same as main meepo
  meepo:SetBaseStrength(mainMeepo:GetStrength())
  meepo:SetBaseAgility(mainMeepo:GetAgility())
  meepo:SetBaseIntellect(mainMeepo:GetIntellect())
  meepo:CalculateStatBonus(true)

  -- Set clone level the same as main meepo
  --while meepo.GetLevel(meepo) < mainMeepo.GetLevel(mainMeepo) do
    --meepo:AddExperience(10, DOTA_ModifyXP_Unspecified, false, false)
  --end

  -- Preventing clone from respawning
  --meepo:SetRespawnsDisabled(true)

  --LevelAbilitiesForAllMeepos(mainMeepo) -- This should be done only on the main meepo
end

function modifier_meepo_divided_we_stand_oaa:OnDeath(event)
  local parent = self:GetParent()

  if event.unit ~= parent then
    return
  end

  local mainMeepo = self:GetCaster()
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      meepo:AddNewModifier(mainMeepo, self:GetAbility(), "modifier_meepo_divided_we_stand_oaa_death", {})
      meepo:AddNoDraw()
    end
  end
end

function modifier_meepo_divided_we_stand_oaa:OnRespawn(keys)
  local parent = self:GetParent()
  local mainMeepo = self:GetCaster()
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      meepo:RemoveModifierByName("modifier_meepo_divided_we_stand_oaa_death")
      meepo:RemoveNoDraw()
      FindClearSpaceForUnit(meepo, mainMeepo:GetAbsOrigin(), true)
      meepo:AddNewModifier(meepo, self:GetAbility(), "modifier_phased", {["duration"] = 0.1})
    end
  end
end
]]

---------------------------------------------------------------------------------------------------
--[[
modifier_meepo_divided_we_stand_oaa_death = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_death:IsHidden()
  return false
end

function modifier_meepo_divided_we_stand_oaa_death:IsDebuff()
  return false
end

function  modifier_meepo_divided_we_stand_oaa_death:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_death:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
  }
end
]]

---------------------------------------------------------------------------------------------------
-- Helper functions
--[[
function LevelAbilitiesForAllMeepos(unit)
  local PID = unit:GetPlayerOwnerID()
  local mainMeepo = PlayerResource:GetSelectedHeroEntity(PID)
  for a = 0, mainMeepo:GetAbilityCount() - 1 do
    local ability = mainMeepo:GetAbilityByIndex(a)
    if ability then
      for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
        if meepo ~= mainMeepo then
          local cloneAbility = meepo:FindAbilityByName(ability:GetAbilityName())
          if ability:GetLevel() > cloneAbility:GetLevel() then
            cloneAbility:SetLevel(ability:GetLevel())
          elseif ability:GetLevel() < cloneAbility:GetLevel() then
            ability:SetLevel(cloneAbility:GetLevel())
            --mainMeepo:SetAbilityPoints(mainMeepo:GetAbilityPoints()-1)
          end
        end
      end
    end
  end
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      meepo:SetAbilityPoints(0)
    end
  end
end

function GetAllMeepos(caster)
  if caster.meepoList then
    return caster.meepoList
  else
    return {caster}
  end
end
]]

---------------------------------------------------------------------------------------------------
--[[
modifier_meepo_divided_we_stand_oaa_passive = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_passive:IsHidden()
  return true
end

function modifier_meepo_divided_we_stand_oaa_passive:IsDebuff()
  return false
end

function modifier_meepo_divided_we_stand_oaa_passive:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_passive:RemoveOnDeath()
  return false
end

function modifier_meepo_divided_we_stand_oaa_passive:IsAura()
	if self:GetParent():PassivesDisabled() then
    return false
  end
	return true
end

function modifier_meepo_divided_we_stand_oaa_passive:GetModifierAura()
  return "modifier_meepo_divided_we_stand_oaa_bonus_buff"
end

function modifier_meepo_divided_we_stand_oaa_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_meepo_divided_we_stand_oaa_passive:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_meepo_divided_we_stand_oaa_passive:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end
]]

---------------------------------------------------------------------------------------------------

modifier_meepo_divided_we_stand_oaa_bonus_buff = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsHidden()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsDebuff()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnCreated()
  local parent = self:GetParent()
  if parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" or not IsServer() then
    self.total_dmg_reduction = 0
    return
  end
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction_per_meepo = ability:GetLevelSpecialValueFor("bonus_dmg_reduction_pct", ability:GetLevel()-1)
    self.radius = ability:GetSpecialValueFor("aura_radius")
  else
    self.dmg_reduction_per_meepo = 4
    self.radius = 600
  end
  self:StartIntervalThink(0)
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnRefresh()
  local parent = self:GetParent()
  if parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" or not IsServer() then
    self.total_dmg_reduction = 0
    return
  end
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction_per_meepo = ability:GetLevelSpecialValueFor("bonus_dmg_reduction_pct", ability:GetLevel()-1)
    self.radius = ability:GetSpecialValueFor("aura_radius")
  else
    self.dmg_reduction_per_meepo = 4
    self.radius = 600
  end
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnIntervalThink()
  local parent = self:GetParent()

  if parent:PassivesDisabled() or parent:IsIllusion() or parent:GetUnitName() ~= "npc_dota_hero_meepo" then
    return
  end

  if not IsServer() then
    return
  end

  -- Find allied heroes
  local heroes = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Find all meepos (clones and meepo prime)
  local meepos = {}
  for _, hero in pairs(heroes) do
    if hero and not hero:IsNull() then
      if hero:GetUnitName() == "npc_dota_hero_meepo" and not hero:IsIllusion() then
        table.insert(meepos, hero)
      end
    end
  end

  self.total_dmg_reduction = #meepos * self.dmg_reduction_per_meepo

  -- Failsafe if something goes wrong
  if self.total_dmg_reduction == 0 then
    self.total_dmg_reduction = self.dmg_reduction_per_meepo
  end

  self:SetStackCount(self.total_dmg_reduction)
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    --MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:GetModifierIncomingDamage_Percentage()
  return -self.total_dmg_reduction
end

--function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnTooltip()
  --return self:GetStackCount()
--end
