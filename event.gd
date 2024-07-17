class_name Event

enum ChainTiming { Before, After, None }

var player : Player
var action : Action = null
var chain_events : Array[Event] = []
var chain_index : int = 0
var chain_parent : Event = null
var chain_timing : ChainTiming = ChainTiming.None
var event_stack : Array[Event] = []
var following_events : Array[Event] = []
var following_event_index := 0
var deferred_players : Array[Player] = []
var has_resolved := false
var unsuccessful := false
var canceled := false
var cancelation_event : Event = null
var handling_finished := false

func get_active_subevent():
	var return_event : Event = null
	if len(following_events) <= following_event_index and len(event_stack) > 0:
		var next_event : Event = event_stack.pop_front()
		following_events.append(next_event)
	if chain_index < len(chain_events):
		return_event = chain_events[chain_index]
		chain_index += 1
	elif following_event_index < len(following_events):
		return_event = following_events[following_event_index]
		following_event_index += 1
	return return_event

func resolve(gm : GameManager):
	print("You called the resolve function of the Event class, this probably was not supposed to happen.")
	
class CardEvent extends Event:
	var card : Card

class SendCardEvent extends CardEvent:
	var origin_cell : Cell
	var origin_is_hand : bool
	var origin_index : int
	var destination_cell : Cell
	var destination_is_hand : bool
	var destination_index : int
	
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
	
	func _init():
		destination_is_hand = true
		
	func resolve(gm : GameManager):
		origin_cell.remove_card(card)
		card.card_owner.hand.add_card(card)
		card.card_position = Card.CardPosition.Hand
		card.controller = card.card_owner
	
class DrawEvent extends SendToHandEvent:
	var draw_stack : Card.CardOrigin
	
	func _init(player : Player, draw_stack : Card.CardOrigin):
		self.draw_stack = draw_stack
		self.player = player
		drawn = true
		match draw_stack:
			Card.CardOrigin.MainDeck:
				origin_cell = player.maindeck_cell
			Card.CardOrigin.ResourceDeck:
				origin_cell = player.resourcedeck_cell
		origin_is_hand = false
		super._init()
	
	func resolve(gm : GameManager):
		if len(origin_cell.cards) == 0:
			print("cant draw from cell %s because it is empty" % origin_cell.to_string())
			return
		card = origin_cell.cards[-1]
		super.resolve(gm)

class TurnDrawEvent extends DrawEvent:
	func _init(player : Player, draw_stack : Card.CardOrigin):
		super._init(player, draw_stack)
	
	func resolve(gm : GameManager):
		super.resolve(gm)
		match gm.game.current_turn.current_phase:
			Game.TurnPhase.Draw1:
				gm.game.current_turn.draw1_drawn = true
			Game.TurnPhase.Draw2:
				gm.game.current_turn.draw2_drawn = true
			_ :
				print("Error in TurnDrawEvent.resolve(): Illegal TurnPhase")

class SendToFieldEvent extends SendCardEvent:
	func _init(player : Player, card : Card, destination_cell : Cell):
		self.player = player
		self.card = card
		self.destination_cell = destination_cell

	func resolve(gm : GameManager):
		if card.card_position == Card.CardPosition.Hand:
			origin_is_hand = true
			card.card_owner.hand.remove_card(card)
			gm.gui.refresh_hand(card.card_owner)
		else:
			origin_is_hand = false
			origin_cell = card.cell
			card.cell.remove_card(card)
		card.cell = destination_cell
		card.card_position = Card.CardPosition.Field
		destination_cell.insert_card(card)
	
class PlayCardEvent extends SendToFieldEvent:
	var resource_payment : PayResourceEvent
	
	func _init(card : Card, destination_cell : Cell):
		super._init(card.card_owner, card, destination_cell)
	
	func resolve(gm : GameManager):
		if resource_payment == null or not resource_payment.unsuccessful:
			super.resolve(gm)

class CallCreatureEvent extends PlayCardEvent:
	func _init(card : Card, destination_cell : Cell):
		super._init(card, destination_cell)
	
	func resolve(gm : GameManager):
		gm.game.current_turn.creature_called = true
		super.resolve(gm)

class CardStatusEvent extends CardEvent:
	pass
	
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
		self.player = player
		self.effect = effect
		
	func resolve(gm : GameManager):
		self.event_stack.append_array(effect.activate.call(gm, effect))

class PlayerEvent extends Event:
	var affected : Player
	
class AdvancePhaseEvent extends PlayerEvent:
	var exiting_phase : Game.TurnPhase
	var entering_phase : Game.TurnPhase
	
	func resolve(gm : GameManager):
		gm.game.enter_phase(entering_phase)
	
	func _init(player : Player, exiting_phase : Game.TurnPhase, entering_phase : Game.TurnPhase):
		self.player = player
		self.exiting_phase = exiting_phase
		self.entering_phase = entering_phase

class ResourceEvent extends PlayerEvent:
	var resources : Game.ResourceList
	
class GainResourceEvent extends ResourceEvent:
	func _init(player : Player, affected : Player, resources : Game.ResourceList):
		self.player = player
		self.affected = affected
		self.resources = resources
	
	func resolve(gm : GameManager):
		affected.resources.combine(resources)

class PayResourceEvent extends ResourceEvent:
	func _init(player : Player, affected : Player, resources : Game.ResourceList):
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
	var choice : Dictionary
	var on_decision : Callable
	
	func resolve(gm : GameManager):
		gm.wait_for_choice(player, Game.GameState.Hot, choice)

class CellChoiceEvent extends ChoiceEvent:
	var scope : Callable
	
	func _init(player : Player, scope : Callable):
		self.player = player
		self.scope = scope
		choice_type = ChoiceType.Cell
	
	func resolve(gm : GameManager):
		choice = { cells = {}}
		var cells : Array[Cell] = scope.call(gm)
		for cell in cells:
			var cell_dict := {type = "cell", label = "choose cell", cell = cell, on_click = func(): on_decision.call(cell, gm)}
			choice.cells[cell.short_name] = cell_dict
		super.resolve(gm)
