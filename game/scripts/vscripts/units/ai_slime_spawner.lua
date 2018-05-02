function Spawn( kv )
	if not IsServer() then
		return
	end

	if thisEntity == nil then
		return
  end
  thisEntity.bForceKill = false

	thisEntity:SetContextThink( "SlimeSpawnerThink", SlimeSpawnerThink, 1 )
end

function SlimeSpawnerThink()
  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
  end

  if thisEntity.bForceKill then
    -- Triggers boss reward
    local hAttackerHero = EntIndexToHScript( thisEntity.KillValues.entindex_attacker )
    thisEntity:Kill(nil, hAttackerHero)
    return -1
  end

  local function SetClones(clone1, clone2)
    thisEntity.clone1 = clone1
    thisEntity.clone2 = clone2
    clone1:OnDeath(OnBossKill)
    clone2:OnDeath(OnBossKill)
  end

  thisEntity.bossHandle1 = CreateUnitByName('npc_dota_boss_slime', thisEntity:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
  thisEntity.bossHandle1.BossTier = thisEntity.BossTier
  thisEntity.bossHandle1.SetClones = SetClones

  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = thisEntity:GetItemInSlot(i)
    if item ~= nil then
      thisEntity.bossHandle1:AddItemByName( item:GetName() )
    end
  end

  return -1
end

function OnBossKill(kv)
  if (not IsValidEntity(thisEntity.clone1) or not thisEntity.clone1:IsAlive()) and
    (not IsValidEntity(thisEntity.clone2) or not thisEntity.clone2:IsAlive()) then
    -- Calling Kill or ForceKill from this handler does not work
    thisEntity.KillValues = kv
    thisEntity.bForceKill = true
    thisEntity:SetContextThink( "SlimeSpawnerThink", SlimeSpawnerThink, 0.1 )
  end
end