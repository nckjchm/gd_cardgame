class_name Action

var player : Player
var events : Array = []
var finished := false

func get_active_event():
	for event in events:
		var return_event : Event
		var active_subevent : Event = event
		while active_subevent != null:
			return_event = active_subevent
			active_subevent = return_event.get_active_subevent()
		if return_event != event or not event.handling_finished:
			return return_event
	return null
	
class Draw extends Action:
	var card
	var stack : Card.CardOrigin
	func _init(player : Player, stack : Card.CardOrigin):
		self.player = player
		self.stack = stack
		events.append(Event.TurnDrawEvent.new(player, stack))
	
class Move extends Action:
	var card
	
	func _init(player : Player, card : Card):
		self.player = player
		self.card = card
		events.append(Event.StartMoveEvent.new(player, card))
	
class Attack extends Action:
	var attacking
	var attacked
	
	func _init(player : Player, card : Card):
		self.player = player
		attacking = card
		events.append(Event.StartAttackEvent.new(player, card))

class PlayCardFromHand extends Action:
	var card : Card
	var cell : Cell
	func _init(player : Player, card : Card):
		self.player = player
		self.card = card
		var resource_payment := Event.PayResourceEvent.new(player, player, card.cost)
		var play_event : Event.PlayCardEvent
		var cell_choice := Event.CellChoiceEvent.new(player, card.play_cell_scope)
		
		if card.card_type == Card.CardType.Creature:
			play_event = Event.CallCreatureEvent.new(card, null)
		else:
			play_event = Event.PlayCardEvent.new(card, null)
		cell_choice.on_decision = (func(choice : Dictionary, gm : GameManager):
			var choice_cell = choice.cell 
			play_event.destination_cell = choice_cell
		)
		play_event.resource_payment = resource_payment
		events.append_array([resource_payment, cell_choice, play_event])

class AdvancePhase extends Action:
	var exiting_phase : Turn.TurnPhase
	var entering_phase : Turn.TurnPhase
	
	func _init(player : Player, exiting_phase : Turn.TurnPhase):
		self.player = player
		self.exiting_phase = exiting_phase
		self.entering_phase = Game.next_phase(exiting_phase)
		events.append(Event.AdvancePhaseEvent.new(player, exiting_phase, entering_phase))

class EndTurn extends AdvancePhase:
	var ending_turn : Turn
	
	func _init(player : Player, ending_turn : Turn):
		self.player = player
		self.ending_turn = ending_turn
		exiting_phase = Turn.TurnPhase.End
		events.append(Event.EndTurnEvent.new(player, ending_turn))

class EffectActivation extends Action:
	var card : Card
	var effect : CardEffect
	
	func _init(player : Player, effect : CardEffect):
		self.player = player
		self.effect = effect
		self.card = effect.card
		events.append(Event.EffectActivationEvent.new(player, effect))

class Recover extends Action:
	var card : Card
	
	func _init(player : Player, card : Card):
		self.player = player
		self.card = card
		events.append(Event.RecoveryEvent.new(player, card))
