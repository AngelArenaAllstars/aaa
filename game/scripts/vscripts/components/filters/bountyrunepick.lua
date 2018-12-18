
if BountyRunePick == nil then
  --Debug:EnableDebugging()
  DebugPrint('Creating new BountyRunePick object')
  BountyRunePick = class({})
end

function BountyRunePick:Init()
  FilterManager:AddFilter(FilterManager.BountyRunePickup, self, Dynamic_Wrap(BountyRunePick, 'Filter'))
end

function BountyRunePick:Filter(filter_table)
  local vanilla_gold_bounty = filter_table.gold_bounty
  local playerID = filter_table.player_id_const
  local vanilla_xp_bounty = filter_table.xp_bounty

  -- Game time in seconds:
  local game_time = HudTimer:GetGameTime()
  -- Game time in minutes:
  game_time = game_time/60
  -- Hero that picked up the rune
  local hero_with_rune = PlayerResource:GetSelectedHeroEntity(playerID)
  -- Team that picked up the rune
  local allied_team = hero_with_rune:GetTeamNumber()

  local enemy_team
  if allied_team == DOTA_TEAM_GOODGUYS then
    enemy_team = DOTA_TEAM_BADGUYS
  elseif allied_team == DOTA_TEAM_BADGUYS then
    enemy_team = DOTA_TEAM_GOODGUYS
  else
    print("Invalid team picked up the rune")
	return false
  end

  -- Player team IDs iterators
  local allied_player_ids = PlayerResource:GetPlayerIDsForTeam(allied_team)
  local enemy_player_ids = PlayerResource:GetPlayerIDsForTeam(enemy_team)

  local AlliedTeamGold = 0
  local AlliedTeamXP = 0
  local EnemyTeamGold = 0
  local EnemyTeamXP = 0

  allied_player_ids:each(function (playerid)
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)
    --AlliedTeamXP = AlliedTeamXP + PlayerResource:GetTotalEarnedXP(playerid)
    if hero then
      AlliedTeamGold = AlliedTeamGold + hero:GetNetworth()
      AlliedTeamXP = AlliedTeamXP + hero:GetCurrentXP()
    end
  end)

  enemy_player_ids:each(function (playerid)
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)
    --EnemyTeamXP = EnemyTeamXP + PlayerResource:GetTotalEarnedXP(playerid)
    if hero then
      EnemyTeamGold = EnemyTeamGold + hero:GetNetworth()
      EnemyTeamXP = EnemyTeamXP + hero:GetCurrentXP()
    end
  end)

  local gold_diff = (EnemyTeamGold - AlliedTeamGold) / (EnemyTeamGold + AlliedTeamGold)
  local xp_diff = (EnemyTeamXP - AlliedTeamXP) / (EnemyTeamXP + AlliedTeamXP)
  local gold_difference = math.max(0, gold_diff)
  local xp_difference = math.max(0, xp_diff)

  local gold_reward = BOUNTY_RUNE_INITIAL_TEAM_GOLD*game_time*(1 + gold_difference*game_time/10)
  local xp_reward = math.ceil(BOUNTY_RUNE_INITIAL_TEAM_XP*game_time*(1 + xp_difference*game_time/10))

  allied_player_ids:each(function (playerid)
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)

    if hero then
      hero:AddExperience(xp_reward, DOTA_ModifyXP_Unspecified, false, true)
    end
  end)

  filter_table.gold_bounty = gold_reward

  return true
end
