class_name Event

enum ChainTiming { Before, After, None }

var player : Player
var action : Action = null
var chain_events : Array[Event] = []
var chain_timing : ChainTiming = ChainTiming.None
var event_stack : Array[Event] = []
var deferred_players : Array[Player] = []
var has_resolved := false
var unsuccessful := false
var canceled := false
var cancelation_event : Event = null
var handling_finished := false
var event_type : String
var parent_event : Event = null:
	get: return parent_event
	set(value):
		parent_event = value
		if parent_event != null:
			self.action = self.parent_event.action

func _init(_player : Player, _parent_event : Event = null):
	player = _player
	parent_event = _parent_event

func get_root_event():
	var indexed_event : Event = self
	while indexed_event.parent_event != null:
		indexed_event = indexed_event.parent_event
	return indexed_event

func get_active_subevent():
	for event in chain_events:
		var event_active_subevent = event.get_active_subevent()
		if event_active_subevent != null:
			return event_active_subevent
		else:
			if not event.handling_finished:
				return event
	if not handling_finished:
		return null
	for event in event_stack:
		if not event.handling_finished:
			return event
		else:
			var event_active_subevent = event.get_active_subevent()
			if event_active_subevent != null:
				return event_active_subevent
	return null

func resolve(_gm : GameManager):
	print("You called the resolve function of the Event class, this probably was not supposed to happen.")
	
class CardEvent extends Event:
	var card : Card
	
	func _init(_player : Player, _card : Card, _parent_event : Event = null):
		super._init(_player, _parent_event)
		card = _card

class SendCardEvent extends CardEvent:
	var origin_cell : Cell = null
	var origin_is_hand : bool = false
	var origin_index : int = 0
	var destination_cell : Cell = null
	var destination_is_hand : bool = false
	var destination_index : int = 0
	
	func _init(_player : Player, _card : Card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
	
	func resolve(gm : GameManager):
		origin_index = card.index_in_stack
		if card.card_position == Card.CardPosition.Hand:
			origin_is_hand = true
			card.card_owner.hand.remove_card(card)
			gm.gui.refresh_hand(card.card_owner)
		else:
			origin_cell = card.cell
			card.cell.remove_card(card)
		if destination_is_hand:
			origin_cell.remove_card(card)
			card.card_owner.hand.add_card(card)
			card.card_position = Card.CardPosition.Hand
			card.controller = card.card_owner
		else:
			card.cell = destination_cell
			card.card_position = Card.CardPosition.Field
			destination_cell.insert_card(card)
	
class SendToGraveEvent extends SendCardEvent:
	func _init(_player, _card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "SendToGrave"
		destination_cell = card.card_owner.graveyard_cell
	
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Graveyard
		card.card_status = Card.CardStatus.Dead
	
class SendToLimboEvent extends SendCardEvent:
	func _init(_player, _card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "SendToLimbo"
		destination_cell = card.card_owner.limbo_cell
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Limbo
		card.card_status = Card.CardStatus.Limbo
	
class SendToBanishmentEvent extends SendCardEvent:
	func _init(_player, _card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "SendToBanishment"
		destination_cell = card.card_owner.banishment_cell
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Banishment
		card.card_status = Card.CardStatus.Banished
	
class SendToDeckEvent extends SendCardEvent:
	func _init(_player, _card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "SendToDeck"
		destination_cell = card.card_owner.maindeck_cell
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Limbo
		card.card_status = Card.CardStatus.Limbo
	
class SendToHandEvent extends SendCardEvent:
	var drawn := false
	
	func _init(_player, _card : Card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "SendToHand"
		destination_is_hand = true
		
	func resolve(gm : GameManager):
		if card != null:
			super.resolve(gm)
			card.card_position = Card.CardPosition.Hand
			card.card_status = Card.CardStatus.Hidden
	
class DrawEvent extends SendToHandEvent:
	var draw_stack : Card.CardOrigin
	
	func _init(_player : Player, _draw_stack : Card.CardOrigin, _parent_event : Event = null):
		super._init(_player, null, _parent_event)
		event_type = "Draw"
		draw_stack = _draw_stack
		drawn = true
		match draw_stack:
			Card.CardOrigin.MainDeck:
				origin_cell = player.maindeck_cell
			Card.CardOrigin.ResourceDeck:
				origin_cell = player.resourcedeck_cell
		origin_is_hand = false
	
	func resolve(gm : GameManager):
		if origin_cell != null and len(origin_cell.cards) > 0:
			card = origin_cell.cards[-1]
			super.resolve(gm)

class TurnDrawEvent extends DrawEvent:
	func _init(_player : Player, _draw_stack : Card.CardOrigin, _parent_event : Event = null):
		super._init(_player, _draw_stack, _parent_event)
		event_type = "TurnDraw"
	
	func resolve(gm : GameManager):
		super.resolve(gm)
		match gm.game.current_turn.current_phase:
			Turn.TurnPhase.Draw1:
				gm.game.current_turn.draw1_drawn = true
			Turn.TurnPhase.Draw2:
				gm.game.current_turn.draw2_drawn = true
			_ :
				print("Error in TurnDrawEvent.resolve(): Illegal TurnPhase")

class SendToFieldEvent extends SendCardEvent:
	func _init(_player : Player, _card : Card, _destination_cell : Cell, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "SendToField"
		destination_cell = _destination_cell
	
	func resolve(gm : GameManager):
		if card != null and destination_cell != null:
			super.resolve(gm)
			card.card_status = Card.CardStatus.Alive
			card.card_position = Card.CardPosition.Field

class StepEvent extends SendToFieldEvent:
	var movement : StartMoveEvent
	var step_candidates : Array[Cell]
	var step_choice : CellChoiceEvent
	var viable := false
	var next_step : StepEvent = null
	
	func _init(_player : Player, _card : Card, _movement : StartMoveEvent):
		super._init(_player, _card, null, _movement)
		event_type = "Step"
		movement = parent_event
		step_choice = CellChoiceEvent.new(self.player, self.card.step_scope, self)
		if len(movement.path) > 1:
			step_choice.alternatives = {end_move = {type = "end_move", movement = movement, card = card, label = "End Move"}}
		step_choice.on_decision = func(decision : Dictionary, _gm : GameManager):
			if "cell" in decision:
				viable = true
				destination_cell = decision.cell
			else:
				event_stack.append(EndMoveEvent.new(player, movement))

	func resolve(gm : GameManager):
		if viable:
			movement.path.append(destination_cell)
			super.resolve(gm)
			if len(movement.path) <= card.speed and not gm.game.hot_event is EndMoveEvent:
				next_step = StepEvent.new(player, card, movement)
				movement.event_stack.append_array([next_step.step_choice, next_step])
			else:
				movement.event_stack.append(EndMoveEvent.new(player, movement))

class PlayCardEvent extends SendToFieldEvent:
	var resource_payment : PayResourceEvent
	
	func _init(_card : Card, _destination_cell : Cell, _parent_event : Event = null):
		super._init(_card.controller if _card is Card else null, _card, _destination_cell, _parent_event)
		event_type = "PlayCard"
	
	func resolve(gm : GameManager):
		if resource_payment == null or not resource_payment.unsuccessful:
			super.resolve(gm)

class CreateCreatureEvent extends PlayCardEvent:
	func _init(_player : Player, _card : Card, _destination_cell : Cell, _parent_event : Event = null):
		super._init(_card, _destination_cell, _parent_event)
		player = _player # This is necessary because Cards can be created by another player than their controller
		event_type = "CreateCreature"
	
	func resolve(gm : GameManager):
		super.resolve(gm)

class CallCreatureEvent extends PlayCardEvent:
	func _init(_card : Card, _destination_cell : Cell, _parent_event : Event = null):
		super._init(_card, _destination_cell, _parent_event)
		event_type = "CallCreature"
	
	func resolve(gm : GameManager):
		gm.game.current_turn.creature_called = true
		super.resolve(gm)

class CardStatusEvent extends CardEvent:
	func _init(_player : Player, _card : Card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "CardStatus"

class AttackEvent extends CardStatusEvent:
	var target : Card
	
	func _init(_player : Player, _card : Card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
	
	func resolve(_gm : GameManager):
		pass

class StartAttackEvent extends AttackEvent:
	var target_choice : CardChoiceEvent
	var attack_execution : ExecuteAttackEvent
	
	func _init(_player : Player, _card : Card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "StartAttack"
	
	func resolve(_gm : GameManager):
		var choice_scope := func(game_manager):
			return card.attack_scope.call(game_manager)
		target_choice = CardChoiceEvent.new(card.controller, choice_scope, self)
		attack_execution = ExecuteAttackEvent.new(player, card, self)
		target_choice.on_decision = func(choicedict : Dictionary, _gm : GameManager):
			if "card" in choicedict:
				attack_execution.target = choicedict.card
				target = choicedict.card
		event_stack.append_array([target_choice, attack_execution])

class ExecuteAttackEvent extends AttackEvent:
	func _init(_player : Player, _card : Card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "ExecuteAttack"
	
	func resolve(_gm : GameManager):
		if target != null:
			var hits_health := false
			var defense_after_damage : int = target.defense - card.attack
			var health_after_damage : int = target.health + defense_after_damage
			if defense_after_damage < 0:
				hits_health = true
				defense_after_damage = 0
			event_stack.append(DefenseChangeEvent.new(player, target, defense_after_damage - target.defense))
			if hits_health:
				event_stack.append(HealthChangeEvent.new(player, target, health_after_damage - target.health))
			event_stack.append(TapStateChangeEvent.new(player, card, 1, self))

class RecoveryEvent extends CardStatusEvent:
	func _init(_player : Player, _card : Card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "Recovery"
	
	func resolve(gm : GameManager):
		if card.tap_status > 0:
			event_stack.append(TapStateChangeEvent.new(player, card, -1))
		if card.defense < card.template.defense:
			event_stack.append(DefenseChangeEvent.new(player, card, card.template.defense - card.defense))
		card.needs_recovery = false
		if gm.game.check_recovery_finished():
			gm.game.current_turn.recovery_done = true
	
class MovementEvent extends CardStatusEvent:
	var ending := false
	var step_cells : Array[Cell] = []
	var current_viable_steps : Array[Cell] = []
	
	func _init(_player, _card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		
	func resolve(gm : GameManager):
		gm.game.game_state = Game.GameState.Cold if ending else Game.GameState.Hot

class StartMoveEvent extends MovementEvent:
	var path : Array[Cell] = []
	
	func _init(_player, _card, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		event_type = "StartMove"
		path.append(card.cell)
	
	func resolve(gm : GameManager):
		card.has_moved = true
		var step_event := StepEvent.new(player, card, self)
		event_stack.append_array([step_event.step_choice, step_event])
		super.resolve(gm)

class EndMoveEvent extends MovementEvent:
	var movement : StartMoveEvent = null
	func _init(_player, start_event):
		movement = start_event
		super._init(_player, start_event.card, start_event)
		event_type = "EndMove"
		ending = true
	
	func resolve(_gm : GameManager):
		if len(movement.path) > movement.card.speed:
			event_stack.append(TapStateChangeEvent.new(movement.player, movement.card, 1))
	
class StatChangeEvent extends CardStatusEvent:
	var amount : int
	var stat : String
	
	func _init(_player : Player, _card : Card, _stat : String, _amount : int, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		stat = _stat
		amount = _amount
	
class HealthChangeEvent extends StatChangeEvent:
	func _init(_player : Player, _card : Card, _amount : int, _parent_event : Event = null):
		super._init(_player, _card, "Health", _amount, _parent_event)
		event_type = "HealthChange"
	
	func resolve(_gm : GameManager):
		card.health += amount
		if card.health <= 0:
			chain_events.append(SendToGraveEvent.new(player, card, self))
	
class DefenseChangeEvent extends StatChangeEvent:
	func _init(_player : Player, _card : Card, _amount : int, _parent_event : Event = null):
		super._init(_player, _card, "Defense", _amount, _parent_event)
		event_type = "DefenseChange"
	
	func resolve(_gm : GameManager):
		card.defense += amount
	
class AttackChangeEvent extends StatChangeEvent:
	func _init(_player : Player, _card : Card, _amount : int, _parent_event : Event = null):
		super._init(_player, _card, "Attack", _amount, _parent_event)
		event_type = "AttackChange"
	
	func resolve(_gm : GameManager):
		card.attack += amount
	
class SpeedChangeEvent extends StatChangeEvent:
	func _init(_player : Player, _card : Card, _amount : int, _parent_event : Event = null):
		super._init(_player, _card, "Speed", _amount, _parent_event)
		event_type = "SpeedChange"
	
	func resolve(_gm : GameManager):
		card.speed += amount
	
class TapStateChangeEvent extends CardStatusEvent:
	var amount : int
	
	func _init(_player : Player, _card : Card, _amount : int, _parent_event : Event = null):
		super._init(_player, _card, _parent_event)
		amount = _amount
		event_type="TapStateChange"
		
	func resolve(_gm : GameManager):
		card.tap_status += amount
		if card.tap_status > 2:
			print("Card %s has been overtapped to %d" % [str(card), card.tap_status])
			card.tap_status = 2
		if card.tap_status < 0:
			print("Card %s has been undertapped to %d" % [str(card), card.tap_status])
			card.tap_status = 0

"""
class MicroStateChangeEvent extends CardStatusEvent:
	var microstate_key : String
	var before
	var after

class CardTypeChangeEvent extends CardStatusEvent:
	var before : Card.CardType
	var after : Card.CardType

class CardColorChangeEvent extends CardStatusEvent:
	var before : Card.CardColor
	var after : Card.CardColor

class CardAspectChangeEvent extends CardStatusEvent:
	var aspect : Card.CardAspect
	var added : bool
	var removed : bool
"""

class EffectEvent extends CardEvent:
	var effect : CardEffect
	
	func _init(_player, _effect, _parent_event : Event = null):
		super._init(_player, _effect.card, _parent_event)
		effect = _effect
	
class EffectActivationEvent extends EffectEvent:
	func _init(_player, _effect, _parent_event : Event = null):
		super._init(_player, _effect, _parent_event)
		event_type="EffectActivation"
		
	func resolve(gm : GameManager):
		self.event_stack.append_array(effect.activate.call(gm, effect))

class PlayerEvent extends Event:
	var affected : Player
	
	func _init(_player : Player, _affected : Player, _parent_event : Event = null):
		super._init(_player, _parent_event)
		affected = _affected
	
class AdvancePhaseEvent extends PlayerEvent:
	var exiting_phase : Turn.TurnPhase
	var entering_phase : Turn.TurnPhase
	
	func _init(_player : Player, _exiting_phase : Turn.TurnPhase, _parent_event : Event = null):
		super._init(_player, _player, _parent_event)
		event_type="AdvancePhase"
		exiting_phase = _exiting_phase
		entering_phase = Game.next_phase(exiting_phase)
	
	func resolve(gm : GameManager):
		gm.game.enter_phase(entering_phase)

class EndTurnEvent extends PlayerEvent:
	var ending_turn
	
	func _init(_player : Player, _ending_turn : Turn, _parent_event : Event = null):
		super._init(_player, _player, _parent_event)
		event_type = "EndTurn"
		ending_turn = _ending_turn
	
	func resolve(gm : GameManager):
		gm.game.new_turn()

class ResourceEvent extends PlayerEvent:
	var resources : ResourceList
	
	func _init(_player : Player, _affected: Player, _resources : ResourceList, _parent_event : Event = null):
		super._init(_player, _affected, _parent_event)
		resources = _resources
		
	
class GainResourceEvent extends ResourceEvent:
	func _init(_player : Player, _affected : Player, _resources : ResourceList, _parent_event : Event = null):
		super._init(_player, _affected, _resources, _parent_event)
		event_type="GainResource"
	
	func resolve(_gm : GameManager):
		affected.resources.combine(resources)

class PayResourceEvent extends ResourceEvent:
	func _init(_player : Player, _affected : Player, _resources : ResourceList, _parent_event : Event = null):
		super._init(_player, _affected, _resources, _parent_event)
		event_type="PayResource"
	
	func resolve(_gm : GameManager):
		if affected.resources.check_coverage(resources):
			affected.resources.reduce(resources)
		else:
			unsuccessful = true

class ChoiceEvent extends PlayerEvent:
	enum ChoiceType { Cell, Card, Option }
	var choice_type : ChoiceType
	var choice : Dictionary = {}
	var alternatives : Dictionary = {}
	var on_decision : Callable
	var create_popup := false
	
	func _init(_player : Player, _parent_event : Event):
		super._init(_player, _player, _parent_event)
		event_type = "Choice"
	
	func resolve(gm : GameManager):
		if not alternatives.is_empty():
			choice.alternatives = {}
		for key in alternatives:
			choice.alternatives[key] = alternatives[key]
			choice.alternatives[key].on_click = func():
				gm.register_choice(["alternatives", key])
		gm.wait_for_choice(player, Game.GameState.Hot, choice)
		if create_popup:
			gm.gui.open_choice_popup_menu()

class CardChoiceEvent extends ChoiceEvent:
	var scope : Callable
	
	func _init(_player : Player, _scope : Callable, _parent_event : Event = null):
		super._init(_player, _parent_event)
		event_type = "CardChoice"
		scope = _scope
		choice_type = ChoiceType.Card
	
	func resolve(gm : GameManager):
		var cards : Array[Card] = scope.call(gm)
		if len(cards) > 0:
			choice = { cards = {}}
			for card in cards:
				var card_dict := {type = "card", label = "choose card", card = card, event = self, on_decision = on_decision}
				card_dict.on_click = func():
					gm.register_choice(["cards", str(card.id)])
				choice.cards[str(card.id)] = card_dict
		super.resolve(gm)

class CellChoiceEvent extends ChoiceEvent:
	var scope : Callable
	
	func _init(_player : Player, _scope : Callable, _parent_event : Event = null):
		super._init(_player, _parent_event)
		event_type="CellChoice"
		scope = _scope
		choice_type = ChoiceType.Cell
	
	func resolve(gm : GameManager):
		var cells : Array[Cell] = scope.call(gm)
		if len(cells) > 0:
			choice = { cells = {}}
			for cell in cells:
				var cell_dict := {type = "cell", label = "choose cell", cell = cell, event = self, on_decision = on_decision}
				cell_dict.on_click = func():
					gm.register_choice(["cells", cell.short_name])
				choice.cells[cell.short_name] = cell_dict
		super.resolve(gm)
