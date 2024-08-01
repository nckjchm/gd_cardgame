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
	func _init(_player : Player, _stack : Card.CardOrigin):
		player = _player
		stack = _stack
		events.append(Event.TurnDrawEvent.new(player, stack))
	
class Move extends Action:
	var card
	
	func _init(_player : Player, _card : Card):
		player = _player
		card = _card
		events.append(Event.StartMoveEvent.new(player, card))
	
class Attack extends Action:
	var attacking
	var attacked
	
	func _init(_player : Player, _card : Card):
		player = _player
		attacking = _card
		events.append(Event.StartAttackEvent.new(player, attacking))

class PlayCardFromHand extends Action:
	var card : Card
	var cell : Cell
	func _init(_player : Player, _card : Card):
		player = _player
		card = _card
		var resource_payment := Event.PayResourceEvent.new(player, player, card.cost)
		var play_event : Event.PlayCardEvent
		var cell_choice := Event.CellChoiceEvent.new(player, card.play_cell_scope)
		
		if card.card_type == Card.CardType.Creature:
			play_event = Event.CallCreatureEvent.new(card, null)
		else:
			play_event = Event.PlayCardEvent.new(card, null)
		cell_choice.on_decision = (func(choice : Dictionary, _gm : GameManager):
			var choice_cell = choice.cell 
			play_event.destination_cell = choice_cell
		)
		play_event.resource_payment = resource_payment
		events.append_array([resource_payment, cell_choice, play_event])

class AdvancePhase extends Action:
	var exiting_phase : Turn.TurnPhase
	var entering_phase : Turn.TurnPhase
	var advancement_event : Event.AdvancePhaseEvent
	
	func _init(_player : Player, _exiting_phase : Turn.TurnPhase):
		player = _player
		exiting_phase = _exiting_phase
		advancement_event = Event.AdvancePhaseEvent.new(player, exiting_phase)
		events.append(advancement_event)
		entering_phase = advancement_event.entering_phase

class EndTurn extends AdvancePhase:
	var ending_turn : Turn
	
	func _init(_player : Player, _ending_turn : Turn):
		player = _player
		ending_turn = _ending_turn
		exiting_phase = Turn.TurnPhase.End
		events.append(Event.EndTurnEvent.new(player, ending_turn))

class EffectActivation extends Action:
	var card : Card
	var effect : CardEffect
	
	func _init(_player : Player, _effect : CardEffect):
		player = _player
		effect = _effect
		card = effect.card
		events.append(Event.EffectActivationEvent.new(player, effect))

class Recover extends Action:
	var card : Card
	
	func _init(_player : Player, _card : Card):
		player = _player
		card = _card
		events.append(Event.RecoveryEvent.new(player, card))

class RecoverAll extends Action:
	var cards_to_recover : Array[Card]
	
	func _init(_player : Player):
		player = _player
		cards_to_recover.assign(player.cards.filter(func(card : Card): return card.needs_recovery))
		for card in cards_to_recover:
			events.append(Event.RecoveryEvent.new(player, card))
