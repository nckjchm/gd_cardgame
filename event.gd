class_name Event

enum ChainTiming { Before, After, None }

var player : Player
var action : Action = null
var chain_events : Array[Event] = []
var parent_event : Event = null
var chain_timing : ChainTiming = ChainTiming.None
var event_stack : Array[Event] = []
var deferred_players : Array[Player] = []
var has_resolved := false
var unsuccessful := false
var canceled := false
var cancelation_event : Event = null
var handling_finished := false
var event_type : String

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

func resolve(gm : GameManager):
	print("You called the resolve function of the Event class, this probably was not supposed to happen.")
	
class CardEvent extends Event:
	var card : Card

class SendCardEvent extends CardEvent:
	var origin_cell : Cell = null
	var origin_is_hand : bool = false
	var origin_index : int = 0
	var destination_cell : Cell = null
	var destination_is_hand : bool = false
	var destination_index : int = 0
	
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
	func _init(player, card):
		self.player = player
		self.card = card
		destination_cell = card.card_owner.graveyard_cell
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Graveyard
		card.card_status = Card.CardStatus.Dead
	
class SendToLimboEvent extends SendCardEvent:
	func _init(player, card):
		self.player = player
		self.card = card
		destination_cell = card.card_owner.limbo_cell
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Limbo
		card.card_status = Card.CardStatus.Limbo
	
class SendToBanishmentEvent extends SendCardEvent:
	func _init(player, card):
		self.player = player
		self.card = card
		destination_cell = card.card_owner.banishment_cell
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Banishment
		card.card_status = Card.CardStatus.Banished
	
class SendToDeckEvent extends SendCardEvent:
	func _init(player, card):
		self.player = player
		self.card = card
		destination_cell = card.card_owner.maindeck_cell
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Limbo
		card.card_status = Card.CardStatus.Limbo
	
class SendToHandEvent extends SendCardEvent:
	var drawn := false
	
	func _init(player):
		self.player = player
		event_type = "SendToHand"
		destination_is_hand = true
		
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_position = Card.CardPosition.Hand
		card.card_status = Card.CardStatus.Hidden
	
class DrawEvent extends SendToHandEvent:
	var draw_stack : Card.CardOrigin
	
	func _init(player : Player, draw_stack : Card.CardOrigin):
		super._init(player)
		event_type = "Draw"
		self.draw_stack = draw_stack
		drawn = true
		match draw_stack:
			Card.CardOrigin.MainDeck:
				origin_cell = player.maindeck_cell
			Card.CardOrigin.ResourceDeck:
				origin_cell = player.resourcedeck_cell
		origin_is_hand = false
	
	func resolve(gm : GameManager):
		if len(origin_cell.cards) == 0:
			print("cant draw from cell %s because it is empty" % origin_cell.to_string())
			return
		card = origin_cell.cards[-1]
		super.resolve(gm)

class TurnDrawEvent extends DrawEvent:
	func _init(player : Player, draw_stack : Card.CardOrigin):
		super._init(player, draw_stack)
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
	func _init(player : Player, card : Card, destination_cell : Cell):
		event_type = "SendToField"
		self.player = player
		self.card = card
		self.destination_cell = destination_cell
	
	func resolve(gm : GameManager):
		super.resolve(gm)
		card.card_status = Card.CardStatus.Alive
		card.card_position = Card.CardPosition.Field

class StepEvent extends SendToFieldEvent:
	var movement : StartMoveEvent
	var step_candidates : Array[Cell]
	var step_choice : CellChoiceEvent
	var viable := false
	var next_step : StepEvent = null
	
	func _init(player : Player, card : Card, movement : StartMoveEvent):
		super._init(player, card, destination_cell)
		event_type = "Step"
		self.movement = movement
		step_choice = CellChoiceEvent.new(self.player, self.card.step_scope)
		if len(movement.path) > 1:
			step_choice.alternatives = {end_move = {type = "end_move", movement = movement, card = card, label = "End Move"}}
		var on_decision := func(decision : Dictionary, gm : GameManager):
			if "cell" in decision:
				viable = true
				destination_cell = decision.cell
			else:
				event_stack.append(EndMoveEvent.new(player, movement))
		step_choice.on_decision = on_decision
		
		
	func resolve(gm : GameManager):
		if viable:
			movement.path.append(destination_cell)
			super.resolve(gm)
			if len(movement.path) <= card.speed and not gm.game.hot_event is EndMoveEvent:
				next_step = StepEvent.new(player, card, movement)
				event_stack.append_array([next_step.step_choice, next_step])
			else:
				event_stack.append(EndMoveEvent.new(player, movement))

class PlayCardEvent extends SendToFieldEvent:
	var resource_payment : PayResourceEvent
	
	func _init(card : Card, destination_cell : Cell):
		super._init(card.card_owner, card, destination_cell)
		event_type = "PlayCard"
	
	func resolve(gm : GameManager):
		if resource_payment == null or not resource_payment.unsuccessful:
			super.resolve(gm)

class CallCreatureEvent extends PlayCardEvent:
	func _init(card : Card, destination_cell : Cell):
		super._init(card, destination_cell)
		event_type = "CallCreature"
	
	func resolve(gm : GameManager):
		gm.game.current_turn.creature_called = true
		super.resolve(gm)

class CardStatusEvent extends CardEvent:
	func _init(player : Player, card : Card):
		event_type = "CardStatus"
		self.player = player
		self.card = card

class AttackEvent extends CardStatusEvent:
	var target : Card

class StartAttackEvent extends AttackEvent:
	var target_choice : CardChoiceEvent
	var attack_execution : ExecuteAttackEvent
	
	func _init(player : Player, card : Card):
		event_type = "Start Attack"
		self.player = player
		self.card = card
	
	func resolve(gm : GameManager):
		var choice_scope := func():
			return card.attack_scope.call(gm)
		target_choice = CardChoiceEvent.new(card.controller, choice_scope)
		attack_execution = ExecuteAttackEvent.new(player, card)
		target_choice.on_decision = func(choicedict : Dictionary, gm : GameManager):
			if "card" in choicedict:
				attack_execution.target = choicedict.card
				target = choicedict.card
		event_stack.append_array([target_choice, attack_execution])

class ExecuteAttackEvent extends AttackEvent:
	func _init(player : Player, card : Card):
		event_type = "Execute Attack"
		self.player = player
		self.card = card
	
	func resolve(gm : GameManager):
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

class RecoveryEvent extends CardStatusEvent:
	func _init(player : Player, card : Card):
		event_type = "Recovery"
		self.player = player
		self.card = card
	
	func resolve(gm : GameManager):
		if card.tap_status > 0:
			event_stack.append(TapStateChangeEvent.new(player, card, -1))
		if card.defense < card.template.defense:
			event_stack.append(DefenseChangeEvent.new(player, card, card.template.defense - card.defense))
		card.needs_recovery = false
		for card_i in card.controller.cards:
			if card.needs_recovery:
				return
		gm.game.current_turn.recovery_done = true
	
class MovementEvent extends CardStatusEvent:
	var ending := false
	var step_cells : Array[Cell] = []
	var current_viable_steps : Array[Cell] = []
	
	func _init(player, card):
		super._init(player, card)
		
	func resolve(gm : GameManager):
		gm.game.game_state = Game.GameState.Cold if ending else Game.GameState.Hot

class StartMoveEvent extends MovementEvent:
	var path : Array[Cell] = []
	
	func _init(player, card):
		super._init(player, card)
		event_type = "StartMove"
		path.append(card.cell)
	
	func resolve(gm : GameManager):
		card.has_moved = true
		var step_event := StepEvent.new(player, card, self)
		event_stack.append_array([step_event.step_choice, step_event])
		super.resolve(gm)

class EndMoveEvent extends MovementEvent:
	var movement : StartMoveEvent = null
	func _init(player, start_event):
		movement = start_event
		super._init(player, start_event.card)
		event_type = "EndMove"
		ending = true
	
	func resolve(gm : GameManager):
		if len(movement.path) > movement.card.speed:
			event_stack.append(TapStateChangeEvent.new(movement.player, movement.card, 1))
	
class StatChangeEvent extends CardStatusEvent:
	var amount : int
	var stat : String
	
class HealthChangeEvent extends StatChangeEvent:
	func _init(player : Player, card : Card, amount : int):
		event_type = "Health Change"
		stat = "Health"
		self.player = player
		self.card = card
		self.amount = amount
	
	func resolve(gm : GameManager):
		card.health += amount
	
class DefenseChangeEvent extends StatChangeEvent:
	func _init(player : Player, card : Card, amount : int):
		event_type = "Defense Change"
		stat = "Defense"
		self.player = player
		self.card = card
		self.amount = amount
	
	func resolve(gm : GameManager):
		card.defense += amount
	
class AttackChangeEvent extends StatChangeEvent:
	func _init(player : Player, card : Card, amount : int):
		event_type = "Attack Change"
		stat = "Attack"
		self.player = player
		self.card = card
		self.amount = amount
	
	func resolve(gm : GameManager):
		card.attack += amount
	
class SpeedChangeEvent extends StatChangeEvent:
	func _init(player : Player, card : Card, amount : int):
		event_type = "Speed Change"
		stat = "Speed"
		self.player = player
		self.card = card
		self.amount = amount
	
	func resolve(gm : GameManager):
		card.speed += amount
	
class TapStateChangeEvent extends CardStatusEvent:
	var amount : int
	
	func _init(player : Player, card : Card, amount : int):
		self.player = player
		self.amount = amount
		self.card = card
		event_type="TapStateChange"
		
	func resolve(gm : GameManager):
		card.tap_status += amount
		if card.tap_status > 2:
			print("Card %s has been overtapped to %d" % [str(card), card.tap_status])
			card.tap_status = 2
		if card.tap_status < 0:
			print("Card %s has been undertapped to %d" % [str(card), card.tap_status])
			card.tap_status = 0
	
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

class EffectEvent extends CardEvent:
	var effect : CardEffect
	
class EffectActivationEvent extends EffectEvent:
	func _init(player, effect):
		event_type="EffectActivation"
		self.player = player
		self.effect = effect
		
	func resolve(gm : GameManager):
		self.event_stack.append_array(effect.activate.call(gm, effect))

class PlayerEvent extends Event:
	var affected : Player
	
class AdvancePhaseEvent extends PlayerEvent:
	var exiting_phase : Turn.TurnPhase
	var entering_phase : Turn.TurnPhase
	
	func _init(player : Player, exiting_phase : Turn.TurnPhase, entering_phase : Turn.TurnPhase):
		event_type="AdvancePhase"
		self.player = player
		self.exiting_phase = exiting_phase
		self.entering_phase = entering_phase
	
	func resolve(gm : GameManager):
		gm.game.enter_phase(entering_phase)

class EndTurnEvent extends PlayerEvent:
	var ending_turn
	
	func _init(player : Player, turn : Turn):
		self.player = player
		self.ending_turn = turn
	
	func resolve(gm : GameManager):
		gm.game.new_turn()

class ResourceEvent extends PlayerEvent:
	var resources : ResourceList
	
class GainResourceEvent extends ResourceEvent:
	func _init(player : Player, affected : Player, resources : ResourceList):
		event_type="GainResource"
		self.player = player
		self.affected = affected
		self.resources = resources
	
	func resolve(gm : GameManager):
		affected.resources.combine(resources)

class PayResourceEvent extends ResourceEvent:
	func _init(player : Player, affected : Player, resources : ResourceList):
		event_type="PayResource"
		self.player = player
		self.affected = affected
		self.resources = resources
	
	func resolve(gm : GameManager):
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
	
	func resolve(gm : GameManager):
		for key in alternatives:
			choice[key] = alternatives[key]
			choice[key].on_click = func():
				on_decision.call(choice[key], gm)
				gm.register_choice(choice[key])
		gm.wait_for_choice(player, Game.GameState.Hot, choice)

class CardChoiceEvent extends ChoiceEvent:
	var scope : Callable
	
	func _init(player : Player, scope : Callable):
		event_type = "CardChoice"
		self.player = player
		self.scope = scope
		choice_type = ChoiceType.Card
	
	func resolve(gm : GameManager):
		var cards : Array[Card] = scope.call()
		if len(cards) > 0:
			choice = { cards = {}}
			for card in cards:
				var choicedict := {card = card, event = self}
				var on_click = func():
					on_decision.call(choicedict, gm)
					gm.register_choice(choicedict)
				var card_dict := {type = "card", label = "choose card", card = card, on_click = on_click}
				choice.cards[str(card.id)] = card_dict
		super.resolve(gm)

class CellChoiceEvent extends ChoiceEvent:
	var scope : Callable
	
	func _init(player : Player, scope : Callable):
		event_type="CellChoice"
		self.player = player
		self.scope = scope
		choice_type = ChoiceType.Cell
	
	func resolve(gm : GameManager):
		var cells : Array[Cell] = scope.call(gm)
		if len(cells) > 0:
			choice = { cells = {}}
			for cell in cells:
				var choicedict := {cell = cell, event = self}
				var on_click = func():
					on_decision.call(choicedict, gm)
					gm.register_choice(choicedict)
				var cell_dict := {type = "cell", label = "choose cell", cell = cell, on_click = on_click}
				choice.cells[cell.short_name] = cell_dict
		super.resolve(gm)
