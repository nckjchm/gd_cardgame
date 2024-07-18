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
	pass
	
class SendToLimboEvent extends SendCardEvent:
	pass
	
class SendToBanishmentEvent extends SendCardEvent:
	pass
	
class SendToDeckEvent extends SendCardEvent:
	pass
	
class SendToHandEvent extends SendCardEvent:
	var drawn := false
	
	func _init(player):
		self.player = player
		event_type = "SendToHand"
		destination_is_hand = true
		
	func resolve(gm : GameManager):
		super.resolve(gm)
	
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
		step_choice.on_decision = func(decision : Dictionary, gm : GameManager):
			if "cell" in decision:
				viable = true
				destination_cell = decision.cell
		
	func resolve(gm : GameManager):
		movement.path.append(destination_cell)
		if viable:
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
		if not len(movement.path) <= movement.card.speed + 1:
			event_stack.append(TapStateChangeEvent.new(movement.player, movement.card, 1))
	
class StatChangeEvent extends CardStatusEvent:
	var amount : int
	
class HealthChangeEvent extends StatChangeEvent:
	pass
	
class DefenseChangeEvent extends StatChangeEvent:
	pass
	
class AttackChangeEvent extends StatChangeEvent:
	pass
	
class SpeedChangeEvent extends StatChangeEvent:
	pass
	
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
	
	func resolve(gm : GameManager):
		gm.game.enter_phase(entering_phase)
	
	func _init(player : Player, exiting_phase : Turn.TurnPhase, entering_phase : Turn.TurnPhase):
		event_type="AdvancePhase"
		self.player = player
		self.exiting_phase = exiting_phase
		self.entering_phase = entering_phase

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
				gm.register_choice(choice[key])
		gm.wait_for_choice(player, Game.GameState.Hot, choice)

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
