
SaveLoadState = SaveLoadState or class({})

Debug:EnableDebugging()

local SaveLoadModules = {
  creeps = CreepCamps,
  time = HudTimer,
  points = PointsManager,
  bosses = BossSpawner,
  gold = Gold,
  heroes = SaveLoadStateHero
}

function SaveLoadState:Init ()
  -- start auto-saving when we should?
  Timers:CreateTimer(5, function ()
    local data = self:GetState()
    DebugPrintTable(data)
    DebugPrint(json.encode(data))
    return 5
  end)
  ChatCommand:LinkDevCommand("-load", function ()
    -- test state
    self:LoadState({
      bosses = {
        ["-3072/-4224/320"] = 2,
        ["-3072/4352/320"] = 1,
        ["-4352/-2048/448"] = 4,
        ["-4352/2048/448"] = 6,
        ["0/-3200/320"] = 1,
        ["0/3200/320"] = 7,
        ["3072/-4224/320"] = 2,
        ["3072/4352/320"] = 2,
        ["4352/-2048/448"] = 2,
        ["4352/2048/448"] = 3,
      },
      creeps = {
        power = 3,
      },
      gold = {
        [0] = 524321,
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
        [17] = 0,
        [18] = 0,
        [19] = 0,
        [20] = 0,
        [21] = 0,
        [22] = 0,
        [23] = 0,
        [24] = 0,
      },
      heroes = {
        [0] = {
          abilities = {
            abilityPoints = 9,
            generic_hidden = {
              cooldown = 0,
              level = 0,
            },
            medusa_mana_shield = {
              cooldown = 0,
              level = 1,
            },
            medusa_mystic_snake = {
              cooldown = 0,
              level = 1,
            },
            medusa_split_shot = {
              cooldown = 0,
              level = 1,
            },
            medusa_stone_gaze = {
              cooldown = 17,
              level = 3,
            },
            special_bonus_attack_damage_20 = {
              cooldown = 0,
              level = 0,
            },
            special_bonus_attack_speed_30 = {
              cooldown = 0,
              level = 1,
            },
            special_bonus_evasion_15 = {
              cooldown = 0,
              level = 1,
            },
            special_bonus_mp_700 = {
              cooldown = 0,
              level = 0,
            },
            special_bonus_unique_medusa = {
              cooldown = 0,
              level = 1,
            },
            special_bonus_unique_medusa_2 = {
              cooldown = 0,
              level = 0,
            },
            special_bonus_unique_medusa_3 = {
              cooldown = 0,
              level = 0,
            },
            special_bonus_unique_medusa_4 = {
              cooldown = 0,
              level = 0,
            },
          },
          hp = 1780,
          items = {
            slot1 = {
              charges = 3,
              cooldown = 0,
              name = 'item_ward_observer',
            },
            slot11 = {
              charges = 14,
              cooldown = 0,
              name = 'item_bloodstone_5',
            },
            slot2 = {
              charges = 0,
              cooldown = 0,
              name = 'item_devDagon',
            },
            slot3 = {
              charges = 0,
              cooldown = 0,
              name = 'item_heart',
            },
            slot4 = {
              charges = 1,
              cooldown = 0,
              name = 'item_tpscroll',
            },
            slot5 = {
              charges = 2,
              cooldown = 0,
              name = 'item_dust',
            },
            slot7 = {
              charges = 0,
              cooldown = 0,
              name = 'item_devastator_4',
            },
            slot9 = {
              charges = 1,
              cooldown = 0,
              name = 'item_azazel_wall_4',
            }
          },
          location = {
            [1] = -5052.3349609375,
            [2] = -16.174743652344,
            [3] = 384,
          },
          mana = 303,
          xp = 18540,
        },
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
        [5] = nil,
        [6] = nil,
        [7] = nil,
        [8] = nil,
        [9] = nil,
        [10] = nil,
        [11] = nil,
        [12] = nil,
        [13] = nil,
        [14] = nil,
        [15] = nil,
        [16] = nil,
        [17] = nil,
        [18] = nil,
        [19] = nil,
        [20] = nil,
        [21] = nil,
        [22] = nil,
        [23] = nil,
        [24] = nil,
      },
      points = {
        badScore = 0,
        goodScore = 0,
        limit = 100,
      },
      time = {
        day = 0.63465321063995,
        time = 186,
      }
    })
  end)
end

function SaveLoadState:GetState ()
  local state = {}
  for name,Module in pairs(SaveLoadModules) do
    state[name] = Module:GetState()
  end

  return state
end

function SaveLoadState:LoadState (state)
  for name,Module in pairs(SaveLoadModules) do
    Module:LoadState(state[name])
  end
end
