var console = {
  log: $.Msg.bind($)
};

(function () {
  hideShowUI(Game.GetState());
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    listenToGameEvent('aaa_state_change', onStateChange);
    listenToGameEvent('gamelength_vote_confirmed', onVotingDone);
  }

  function onStateChange (data) {
    hideShowUI(data.newState);
  }
  function onVotingDone (data) {
    FindDotaHudElement('PreGame').FindChildTraverse( 'GameModeLabel' ).text = $.Localize(("#aaa_game_length_" + data.length + "_title").toLowerCase());
  }
}());

function hideShowUI (state) {
  if (state === 2) {
    hidePregameUI();
  } else if (state < 7) {
    showPregameUI();
  } else {
    hidePregameUI();
  }
}

function hidePregameUI () {
  FindDotaHudElement('PreGame').style.opacity = 0;
  FindDotaHudElement('PreGame').style.visibility = 'collapse';
}
function showPregameUI () {
  FindDotaHudElement('PreGame').style.opacity = 1;
  FindDotaHudElement('PreGame').style.visibility = 'visible';
}

function FindDotaHudElement(id) {
  return GetDotaHud().FindChildTraverse(id)
}

function GetDotaHud() {
  var p = $.GetContextPanel()
  try {
    while (true) {
      if (p.id === "Hud")
        return p
      else
        p = p.GetParent()
    }
  } catch (e) {}
}

function listenToGameEvent (event, handler ) {
  var handle = GameEvents.Subscribe(event, handleWrapper);
  var doneListening = false;

  return unlisten;

  function unlisten () {
    doneListening = true;
    GameEvents.Unsubscribe(handle);
  }
  function handleWrapper () {
    if (doneListening) {
      return;
    }
    handler.apply(this, arguments);
  }
}
