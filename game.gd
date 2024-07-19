class_name Game

enum GameState { Preparation, Hot, Cold, Paused, Finished }

var turns := []
var players : Array[Player]
var turnplayer_seat = 0
var game_state = GameState.Preparation
var current_turn : Turn = null
var hot_action : Action = null
var hot_event : Event = null
var all_cards : Array[Card]

func _init(playerList : Array[Player]):
	players = playerList
	for player_index in range(len(players)):
		var player : Player = players[player_index]
		player.hand = Hand.new(player)
		player.resources = ResourceList.new([])
		player.seat = player_index
		player.rotation = int((float(player.seat) / len(players) * 360) + 180) % 360

func init_cards():
	var card_index := 0
	var effect_index := 0
	for player in players:
		var deck_templates = [player.deck.deck_template.main_deck_keys, player.deck.deck_template.resource_deck_keys, player.deck.deck_template.special_deck_keys]
		for deck_template in deck_templates:
			var card_origin : Card.CardOrigin
			match deck_template:
				player.deck.deck_template.main_deck_keys:
					card_origin = Card.CardOrigin.MainDeck
				player.deck.deck_template.resource_deck_keys:
					card_origin = Card.CardOrigin.ResourceDeck
				player.deck.deck_template.special_deck_keys:
					card_origin = Card.CardOrigin.SpecialDeck
			var card_list : Array[Card] = []
			for template_key in deck_template:
				var card : Card = init_card(template_key, card_index, player, card_origin, effect_index)
				card_index += 1
				effect_index += len(card.effects)

func init_card(template_key : String, card_index : int, player : Player, card_origin : Card.CardOrigin, effect_index_start : int):
	var card : Card = CardTemplates.card_prefab.instantiate()
	var card_template = CardTemplates.templates[template_key]
	card.initialize(card_template, card_index, player, card_origin, effect_index_start)
	match card_origin:
		Card.CardOrigin.MainDeck:
			player.maindeck_cell.insert_card(card)
		Card.CardOrigin.ResourceDeck:
			player.resourcedeck_cell.insert_card(card)
		Card.CardOrigin.SpecialDeck:
			player.specialdeck_cell.insert_card(card)
	card.card_owner.cards.append(card)
	all_cards.append(card)
	return card

func start():
	for player in players:
		for i in range(5):
			draw(player, player.maindeck_cell)
	new_turn()
	game_state = GameState.Cold

func new_turn():
	turnplayer_seat = (turnplayer_seat + 1) % len(players)
	current_turn = Turn.new(len(turns)+1, players[turnplayer_seat])
	turns.append(current_turn)
	for card in all_cards:
		card.has_attacked = false
		card.has_moved = false

func next_player(player : Player):
	return players[(player.seat + 1) % len(players)]

func enter_phase(phase : Turn.TurnPhase):
	current_turn.current_phase = phase
	if phase == Turn.TurnPhase.Recovery:
		mark_recovery_targets()

func mark_recovery_targets():
	var targets_available := false
	for card in current_turn.turn_player.cards:
		card.needs_recovery = card.check_recovery_viability()
		if card.needs_recovery:
			targets_available = true
	current_turn.recovery_done = not targets_available

func draw(player : Player, stack : Cell):
	var card : Card = stack.cards[-1]
	stack.remove_card(card)
	card.card_owner.hand.add_card(card)
	card.card_position = Card.CardPosition.Hand

func check_recovery_finished():
	for card in current_turn.turn_player.cards:
		if card.needs_recovery:
			return false
	return true

static func next_phase(phase : Turn.TurnPhase):
	match phase:
		Turn.TurnPhase.Start:
			return Turn.TurnPhase.Recovery
		Turn.TurnPhase.Recovery:
			return Turn.TurnPhase.Draw1
		Turn.TurnPhase.Draw1:
			return Turn.TurnPhase.Main1
		Turn.TurnPhase.Main1:
			return Turn.TurnPhase.Battle
		Turn.TurnPhase.Battle:
			return Turn.TurnPhase.Draw2
		Turn.TurnPhase.Draw2:
			return Turn.TurnPhase.Main2
		Turn.TurnPhase.Main2:
			return Turn.TurnPhase.End
		Turn.TurnPhase.End:
			return Turn.TurnPhase.Start
	print("couldn't match TurnPhase: %s" % phase)


