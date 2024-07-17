class_name Action

var player : Player
var events : Array = []
var finished := false

func get_active_event():
	for event in events:
		if not event.handling_finished:
			var return_event : Event = null
			return_event = event
			var active_subevent = return_event.get_active_subevent()
			while active_subevent != null:
				return_event = active_subevent
				active_subevent = return_event.get_active_subevent()
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
	var path
	
	func _init(player : Player, card : Card):
		self.player = player
		self.card = card
	
class Attack extends Action:
	var attacking
	var attacked
	
	func _init(player : Player, card : Card):
		self.player = player
		attacking = card

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
		cell_choice.on_decision = (func(cell : Cell, gm : GameManager): 
			play_event.destination_cell = cell
			gm.register_choice({cell = cell_choice}))
		play_event.resource_payment = resource_payment
		events.append_array([resource_payment, cell_choice, play_event])

class AdvancePhase extends Action:
	var exiting_phase : Game.TurnPhase
	var entering_phase : Game.TurnPhase
	
	func _init(player : Player, exiting_phase : Game.TurnPhase):
		self.player = player
		self.exiting_phase = exiting_phase
		self.entering_phase = Game.next_phase(exiting_phase)
		events.append(Event.AdvancePhaseEvent.new(player, exiting_phase, entering_phase))

class EndTurn extends AdvancePhase:
	var ending_turn : Game.Turn
	
	func _init(player : Player, ending_turn : Game.Turn):
		self.player = player
		self.ending_turn = ending_turn
		exiting_phase = Game.TurnPhase.End

class EffectActivation extends Action:
	var card : Card
	var effect : CardEffect
	
	func _init(player : Player, effect : CardEffect):
		self.player = player
		self.effect = effect
		self.card = effect.card
		events.append(Event.EffectActivationEvent.new(player, effect))
