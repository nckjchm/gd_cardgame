class_name EffectTemplate

var condition : Callable
var activate : Callable
var long_text : String
var short_text : String
var id : int

class ETGain1YellowMana extends EffectTemplate:
	func _init():
		id = 1
		condition = func(gm : GameManager, effect : CardEffect):
			if effect.card.card_position == Card.CardPosition.Field and effect.card.tap_status == 0:
				if gm.game.game_state == Game.GameState.Cold:
					if gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main1]:
						return true
			return false
		activate = func(gm : GameManager, effect : CardEffect):
			var tapEvent = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var resourceEvent = Event.GainResourceEvent.new(effect.card.controller, effect.card.controller, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 1)]))
			return [tapEvent, resourceEvent]
		short_text = "Gain Mana"
		long_text = "Tap; Gain 1 Yellow Mana."
