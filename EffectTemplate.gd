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
				return true
			return false
		activate = func(gm : GameManager, effect : CardEffect):
			var activationEvent = Event.EffectActivationEvent.new(effect.card.controller, effect)
			var tapEvent = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var resourceEvent = Event.GainResourceEvent.new(effect.card.controller, effect.card.controller, Game.ResourceList.new([Game.ResourceElement.new(Game.ResourceKind.Mana, Card.CardColor.Yellow, 1)]))
			activationEvent.event_stack.append_array([tapEvent, resourceEvent])
		
