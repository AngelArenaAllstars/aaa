
-- Taken from bb template
if NGP == nil then
    DebugPrint ( 'creating new need greed pass controller.' )
    NGP = class({})
end

NGP.itemIndex = 2
NGP.activeItems = {}
NGP.activeTimers = {}
local totalgoodplayers = 0
local totalbadplayers = 0
local ngpItemsGood = {}
local ngpItemsBad = {}

function NGP:Init ()

  -- set initial values for ngp store
  CustomNetTables:SetTableValue( 'ngp', 'good', {
  })
  CustomNetTables:SetTableValue( 'ngp', 'bad', {
  })

  CustomGameEventManager:RegisterListener('ngp_selection', Dynamic_Wrap(NGP, 'PlayerVote'))


  for playerId = 0,19 do
    local player = PlayerResource:GetPlayer(playerId)
    if player ~= nil then
      if player:GetTeam() == 3 then
        totalbadplayers = totalbadplayers + 1
      elseif player:GetTeam() == 2 then
        totalgoodplayers = totalgoodplayers + 1
      end
    end
  end
end

function NGP:PlayerVote (eventSourceIndex, args)
  getGlobalTable(team) 
  -- DebugPrintTable(eventSourceIndex)
  -- DebugPrintTable(args)
  local playerID = eventSourceIndex.PlayerID
  local id = eventSourceIndex.id
  local option = eventSourceIndex.option
  local team = ShortTeamName(PlayerResource:GetTeam(playerID))
  local item = NGP.activeItems[tonumber(id)]
  local heroname = PlayerResource:GetSelectedHeroName(playerID)
  if item.team ~= team then
    Notifications:TopToAll({text="NGP mismatch " .. item.team .. " vs " .. team, duration=2.0})
    return
  end
  item.votes[playerID] = option
  item.heroname[playerID] = heroname

  setTableItem(item, team)
  
  if item.finished == false then
    local totalvoted = 0
    for i = 0,19 do
      if item.votes[i] then
        totalvoted = totalvoted + 1
      end
    end
    if totalvoted > (totalbadplayers-1) and team == "bad" then
      Timers:RemoveTimer(NGP.activeTimers[tonumber(id)])
      NGP:FinishVoting(tonumber(id), team)
    elseif totalvoted > (totalgoodplayers-1) and team == "good" then
      Timers:RemoveTimer(NGP.activeTimers[tonumber(id)])
      NGP:FinishVoting(tonumber(id), team)
    end
  end

  --getGlobalTable(team)
  --DebugPrintTable(ngpItemsGood)
  --DebugPrint("sssss")

end

function NGP:GiveItemToTeam (item, team)
  getGlobalTable(team)

  DebugPrint('item index will be ' .. NGP.itemIndex)
  item.id = NGP.itemIndex
  item.finished = false
  NGP.itemIndex = NGP.itemIndex + 1
  item.team = team
  NGP.activeItems[item.id] = item
  NGP.activeItems[item.id].votes = {}
  NGP.activeItems[item.id].heroname = {}

  setTableItem(item, team)

  NGP.activeTimers[item.id] = Timers:CreateTimer(60, function ()
    NGP:FinishVoting(item.id, team)
  end)
end


function getGlobalTable(team) 
  if team == 'good' then
    ngpItemsGood = CustomNetTables:GetTableValue('ngp', team)
  elseif team == 'bad' then
    ngpItemsBad = CustomNetTables:GetTableValue('ngp', team)
  end
end

function setTableItem(item, team)
  if team == 'good' then
    ngpItemsGood[item.id] = item
  elseif team == 'bad' then
    ngpItemsBad[item.id] = item
  end
  setGlobalTable(team)
end

function setGlobalTable(team) 
  if team == 'good' then
    CustomNetTables:SetTableValue('ngp', team, ngpItemsGood)
  elseif team == 'bad' then
    CustomNetTables:SetTableValue('ngp', team, ngpItemsBad)
  end
end


function NGP:FinishVoting (id, team)

  local item = NGP.activeItems[id]
  item.finished = true
  getGlobalTable(team)
  setTableItem(item, team)


  local needVotes = {}
  local greedVotes = {}
  local passVotes = {}
  for i = 0,19 do
    if item.votes[i] then
      if item.votes[i] == 'need' then
        table.insert(needVotes, i)
      elseif item.votes[i] == 'greed' then
        table.insert(greedVotes, i)
      elseif item.votes[i] == 'pass' then
        table.insert(passVotes, i)
      end
    end
  end

  if #needVotes > 0 then
    -- someone voted need! decide between them...
    local winningPlayer = needVotes[math.random(1, #needVotes)]
    DebugPrint(winningPlayer .. ' won by need!!')
    NGP:GiveItemToPlayer(item, winningPlayer)
    return
  end
  if #greedVotes > 0 then
    -- someone voted need! decide between them...
    local winningPlayer = greedVotes[math.random(1, #greedVotes)]
    DebugPrint(winningPlayer .. ' won by greed!!')
    NGP:GiveItemToPlayer(item, winningPlayer)
    return
  end
  DebugPrint('Everyone Passed!')
end

function NGP:GiveItemToPlayer (item, playerId)
  local player = PlayerResource:GetPlayer(playerId)
  if player == nil then
    DebugPrint('Player is null while trying to give them their reward!')
    return
  end
  local hero = player:GetAssignedHero()
  if hero == nil then
    DebugPrint('Hero of player is null while trying to give them their reward!')
    return
  end
  -- local itemHandle = CreateItem(item.item, hero, hero)
  hero:AddItemByName(item.item)
end

function ShortTeamName(teamId)
  -- DebugPrint(teamId)
  if teamId == 2 then
    return 'good'
  else
    return 'bad'
  end
end
