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
					if gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]:
						return true
			return false
		activate = func(gm : GameManager, effect : CardEffect):
			var tapEvent = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var resourceEvent = Event.GainResourceEvent.new(effect.card.controller, effect.card.controller, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 1)]))
			return [tapEvent, resourceEvent]
		short_text = "Gain Mana"
		long_text = "Tap; Gain 1 Mana."

class ETGain1YellowNutrition extends EffectTemplate:
	func _init():
		id = 1
		condition = func(gm : GameManager, effect : CardEffect):
			if effect.card.card_position == Card.CardPosition.Field and effect.card.tap_status == 0:
				if gm.game.game_state == Game.GameState.Cold:
					if gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]:
						return true
			return false
		activate = func(gm : GameManager, effect : CardEffect):
			var tapEvent = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var resourceEvent = Event.GainResourceEvent.new(effect.card.controller, effect.card.controller, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Nutrition, Card.CardColor.Yellow, 1)]))
			return [tapEvent, resourceEvent]
		short_text = "Gain Nutrition"
		long_text = "Tap; Gain 1 Nutrition."

class ETGain1YellowResourceOfChoice extends EffectTemplate:
	func _init():
		id = 2
		condition = func(gm : GameManager, effect : CardEffect):
			if effect.card.card_position == Card.CardPosition.Field and effect.card.tap_status == 0:
				if gm.game.game_state == Game.GameState.Cold:
					if gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]:
						return true
			return false
		activate = func(gm : GameManager, effect : CardEffect):
			var tapEvent = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var choiceEvent = Event.ChoiceEvent.new(effect.card.controller, null)
			var on_decision := func(decision : Dictionary, gm : GameManager):
				if decision.choice == "mana":
					choiceEvent.event_stack.append(Event.GainResourceEvent.new(gm.current_decider, gm.current_decider, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 1)])))
				else:
					choiceEvent.event_stack.append(Event.GainResourceEvent.new(gm.current_decider, gm.current_decider, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Nutrition, Card.CardColor.Yellow, 1)])))
			choiceEvent.alternatives = {
				gain_mana = {type = "choice", choice = "mana", effect = effect, label = "Gain Mana", on_decision = on_decision},
				gain_nutrition = {type = "choice", choice = "nutrition", effect = effect, label = "Gain Nutrition", on_decision = on_decision}
			}
			choiceEvent.create_popup = true
			return [tapEvent, choiceEvent]
		short_text = "Gain Resource"
		long_text = "Tap; Gain 1 Resource of Choice."
