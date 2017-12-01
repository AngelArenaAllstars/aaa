/* global FindDotaHudElement, GameEvents, $, Players, CustomNetTables */
'use strict';

(function () {
  GameEvents.Subscribe('player_stats_updated', HandleStatChange);
  GameEvents.Subscribe('dota_portrait_unit_stats_changed', HandleStatChange);
  GameEvents.Subscribe('dota_portrait_unit_modifiers_changed', HandleStatChange);
  GameEvents.Subscribe('dota_inventory_changed', HandleStatChange);
  GameEvents.Subscribe('dota_inventory_item_changed', HandleStatChange);
  GameEvents.Subscribe('dota_inventory_changed_query_unit', HandleStatChange);
  GameEvents.Subscribe('dota_player_update_hero_selection', HandleStatChange);
  GameEvents.Subscribe('dota_player_update_selected_unit', HandleStatChange);
  GameEvents.Subscribe('dota_player_update_query_unit', HandleStatChange);
  GameEvents.Subscribe('dota_ability_changed', HandleStatChange);

  CustomNetTables.SubscribeNetTableListener('entity_stats', onEntityStatChange)
}());

var HealthManaContainer = FindDotaHudElement('HealthManaContainer');
var HealthRegenLabel = HealthManaContainer.FindChildTraverse('HealthRegenLabel');
var ManaRegenLabel = HealthManaContainer.FindChildTraverse('ManaRegenLabel');
var blockUpdate = {};

function HandleStatChange () {
  GameEvents.SendCustomGameEventToServer('statprovider_entities_request', {
    entity: Players.GetLocalPlayerPortraitUnit();
  });
}

function onEntityStatChange (arg, updatedEntity, data) {
  var selectedEntity = Players.GetLocalPlayerPortraitUnit();
  if (updatedEntity !== selectedEntity || !data) {
    return;
  }
  HealthRegenLabel.text = FormatRegen(data['HealthRegen']);
  ManaRegenLabel.text = FormatRegen(data['ManaRegen']); // TODO Values are wrong
}

function FormatRegen (number) {
  if (number > 0) {
    number = '+' + number.toFixed(3);
  } else if (number > 0) {
    number = '-' + number.toFixed(3);
  } else {
    number = '±0.00';
  }

  return number;
}
