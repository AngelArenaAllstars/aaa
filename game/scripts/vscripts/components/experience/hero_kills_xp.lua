
if HeroKillXP == nil then
  DebugPrint ( 'Creating new HeroKillXP object.' )
  HeroKillXP = class({})
  Debug.EnabledModules['experience:hero_kills'] = false
end

function HeroKillXP:Init()
  GameEvents:OnHeroKilled(partial(self.HeroDeathHandler, self))
  FilterManager:AddFilter(FilterManager.ModifyExperience, self, Dynamic_Wrap(HeroKillXP, "ExperienceFilter"))
end

function HeroKillXP:ExperienceFilter(keys)
  if keys.reason_const == DOTA_ModifyXP_HeroKill then
    return false
  end
  return true
end

function HeroKillXP:HeroDeathHandler(keys)
  -- Based on HeroKillGold
  if not keys.killer or not keys.killed then
    return
  end

  local killerEntity = keys.killer
  local killedHero = keys.killed
  -- killer is sometimes nil for some reason
  if not killerEntity then
    local killedHeroName
    if killedHero then
      killedHeroName = killedHero:GetName()
    else
      killedHeroName = "Killed entity also nil ??????"
    end
    D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_INFO, "HERO DEATH EVENT FIRED WITH NIL KILLER", {
      ErrorMessage = killedHeroName,
      ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
      GameVersion = GAME_VERSION,
      DedicatedServers = (IsDedicatedServer() and 1) or 0,
      MatchID = tostring(GameRules:GetMatchID())
    })

    return
  end
  local killerTeam = killerEntity:GetTeamNumber()
  local killedTeam = killedHero:GetTeamNumber()

  if killerTeam == killedTeam then
    -- Hero is denied
    return
  end

  if killedHero:IsReincarnating() then
    return
  end

  if killerTeam == DOTA_TEAM_NEUTRALS or killedTeam == DOTA_TEAM_NEUTRALS then
    return
  end

  local killerPlayerID = killerEntity:GetPlayerOwnerID()
  local killedPlayerID = killedHero:GetPlayerOwnerID()
  if killerPlayerID == -1 or killedPlayerID == -1 then
    return
  end

  local killerHero = PlayerResource:GetSelectedHeroEntity(killerPlayerID)
  local killedHeroXP = killedHero:GetCurrentXP()
  local killedHeroStreakXP = 0

  local numAttackers = killedHero:GetNumAttackers()
  local rewardPlayerIDs = iter({killerPlayerID})
  local rewardHeroes = iter({killerHero})
  local distributeCount = 1

  -- Heroes around the killed hero
  local heroes = FindHeroesInRadius(
    killerTeam,
    killedHero:GetAbsOrigin(),
    nil,
    HERO_KILL_XP_RADIUS,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- Handle non-player kills (usually the fountain in OAA's case)
  if not PlayerResource:IsValidTeamPlayerID(killerPlayerID) then
    if numAttackers == 0 then
      -- Distribute xp to all heroes on the killer team
      rewardPlayerIDs = PlayerResource:GetPlayerIDsForTeam(killerTeam)
      distributeCount = math.max(1, length(rewardPlayerIDs))
    elseif numAttackers == 1 then
      -- Give xp to single hero
      rewardPlayerIDs = iter({killedHero:GetAttacker(0)})
    else
      -- Distribute xp to heroes who assisted in kill
      rewardPlayerIDs = range(0, numAttackers - 1)
                          :map(partial(killedHero.GetAttacker, killedHero))
      distributeCount = numAttackers
    end
    rewardHeroes = map(partial(PlayerResource.GetSelectedHeroEntity, PlayerResource), rewardPlayerIDs)
  else
    -- When last hit by a hero from long range (>1500), that hero should always receive xp, regardless of distance
    local killerIsInHeroesTable = iter(heroes)
                                  :map(CallMethod("GetPlayerOwnerID"))
                                  :contains(killerPlayerID)
    if not killerIsInHeroesTable then
      table.insert(heroes, killerHero)
    end

    distributeCount = #heroes
  end

  local xp = math.floor((HERO_XP_BOUNTY_BASE + killedHeroStreakXP + (killedHeroXP * AOE_XP_BONUS_FACTOR)) / distributeCount)

  -- If the killer is not a hero: Give xp to heroes that were involved in a kill
  for _, hero in rewardHeroes:unwrap() do
    if hero then
      hero:AddExperience(xp, DOTA_ModifyXP_RoshanKill, false, true)
    end
  end

  -- If the killer is a hero: Give xp to the killer and to heroes around the killed hero
  for _, hero in ipairs(heroes) do
    if hero then
      hero:AddExperience(xp, DOTA_ModifyXP_RoshanKill, false, true)
    end
  end
end
