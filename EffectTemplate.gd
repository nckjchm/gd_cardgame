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
		activate = func(_gm : GameManager, effect : CardEffect):
			var tapEvent = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var resourceEvent = Event.GainResourceEvent.new(effect.card.controller, effect.card.controller, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 1)]))
			return [tapEvent, resourceEvent]
		short_text = "Gain Mana"
		long_text = "Tap; Gain 1 Mana."

class ETGain1YellowNutrition extends EffectTemplate:
	func _init():
		id = 2
		condition = func(gm : GameManager, effect : CardEffect):
			if effect.card.card_position == Card.CardPosition.Field and effect.card.tap_status == 0:
				if gm.game.game_state == Game.GameState.Cold:
					if gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]:
						return true
			return false
		activate = func(_gm : GameManager, effect : CardEffect):
			var tapEvent = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var resourceEvent = Event.GainResourceEvent.new(effect.card.controller, effect.card.controller, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Nutrition, Card.CardColor.Yellow, 1)]))
			return [tapEvent, resourceEvent]
		short_text = "Gain Nutrition"
		long_text = "Tap; Gain 1 Nutrition."

class ETGain1YellowResourceOfChoice extends EffectTemplate:
	func _init():
		id = 3
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

class ETCreate1YellowCreatureAtCost extends EffectTemplate:
	var card_scope : Callable
	var cell_scope : Callable
	
	func _init():
		id = 4
		card_scope = func(gm : GameManager, effect : CardEffect): 
			return EffectTemplate.def_yellow_humanoid_target_scope(gm, effect).filter(func(card : Card): 
				return card.card_position == Card.CardPosition.Hand and card.controller.resources.check_coverage(card.cost))
		cell_scope = func(gm : GameManager, effect : CardEffect): return EffectTemplate.def_enterable_neighbor_cell_scope(gm, effect)
		condition = func(gm : GameManager, effect : CardEffect):
			if effect.card.card_position == Card.CardPosition.Field and effect.card.tap_status == 0:
				if gm.game.game_state == Game.GameState.Cold:
					if gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]:
						if len(card_scope.call(gm, effect)) > 0 and len(cell_scope.call(gm, effect)) > 0:
							return true
			return false
		activate = func(gm : GameManager, effect : CardEffect):
			var tap_event = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var card_choice = Event.CardChoiceEvent.new(effect.card.controller, func(gm : GameManager): return card_scope.call(gm, effect))
			var cell_choice = Event.CellChoiceEvent.new(effect.card.controller, func(gm : GameManager): return cell_scope.call(gm, effect))
			var pay_resources = Event.PayResourceEvent.new(effect.card.controller, effect.card.controller, null)
			var creation_event = Event.CreateCreatureEvent.new(effect.card.controller, null, null)
			card_choice.on_decision = func(decision : Dictionary, _gm : GameManager):
				pay_resources.resources = decision.card.cost
				creation_event.card = decision.card
			cell_choice.on_decision = func(decision : Dictionary, _gm : GameManager):
				creation_event.destination_cell = decision.cell
			return [tap_event, card_choice, cell_choice, pay_resources, creation_event]
		short_text = "Create from Hand"
		long_text = "Tap; Create 1 Yellow Creature from your Hand at Cost."

class ETTapOneNeighborGainTwoNutrition extends EffectTemplate:
	var card_scope : Callable
				
	func _init():
		id = 5
		card_scope = func(gm : GameManager, effect : CardEffect):
			var cards_in_scope : Array[Card] = []
			var neighbor_cells : Array[Cell] = gm.field.get_cells_in_distance([effect.card.cell], 1)
			for neighbor_cell in neighbor_cells:
				for neighbor_card in neighbor_cell.cards:
					if neighbor_card.controller == effect.card.controller and neighbor_card.card_color == Card.CardColor.Yellow and neighbor_card.card_type == Card.CardType.Creature and Card.CardAspect.Humanoid in neighbor_card.card_aspects:
						cards_in_scope.append(neighbor_card)
			return cards_in_scope
		condition = func(gm : GameManager, effect : CardEffect):
			if effect.card.card_position == Card.CardPosition.Field and effect.card.tap_status == 0:
				if gm.game.game_state == Game.GameState.Cold:
					if gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]:
						return len(card_scope.call(gm, effect)) > 0
			return false
		activate = func(_gm : GameManager, effect : CardEffect):
			var tap_event = Event.TapStateChangeEvent.new(effect.card.controller, effect.card, 1)
			var choice_event := Event.CardChoiceEvent.new(effect.card.controller, func(game_manager): return card_scope.call(game_manager, effect))
			var neighbor_tap_event := Event.TapStateChangeEvent.new(effect.card.controller, null, 1)
			choice_event.on_decision = func(choicedict : Dictionary, _gm : GameManager):
				if "card" in choicedict:
					neighbor_tap_event.card = choicedict.card
			var resource_event = Event.GainResourceEvent.new(effect.card.controller, effect.card.controller, ResourceList.new([ResourceList.ResourceElement.new(ResourceList.ResourceKind.Nutrition, Card.CardColor.Yellow, 2)]))
			return [tap_event, choice_event, neighbor_tap_event, resource_event]
		short_text = "Gain 2 Nutrition"
		long_text = "Tap this Card, Tap one adjacent Yellow Humanoid Creature; Gain 2 Nutrition."

static func def_yellow_humanoid_target_scope(gm : GameManager, effect : CardEffect):
	return gm.game.all_cards.filter(func(card : Card): return card.controller == effect.card.controller and card.card_color == Card.CardColor.Yellow and Card.CardAspect.Humanoid in card.card_aspects)

static func def_enterable_neighbor_cell_scope(gm : GameManager, effect : CardEffect):
	return gm.field.get_cells_in_distance([effect.card.cell], 1).filter(func(cell : Cell):
		for cell_card in cell.cards:
			if not cell_card.can_coexist:
				return false
		return true
	)
