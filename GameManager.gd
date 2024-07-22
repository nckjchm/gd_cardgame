class_name GameManager extends Node

@onready var field : Field = $"../GameViewContainer/FieldVPC/FieldVP/Field"
@onready var input_controller : InputController = $"../InputController"
var game : Game
var current_decider : Player :
	get:
		return current_decider
	set(value):
		current_decider = value
		input_controller.camera.adjust_rotation(value.rotation)
var current_options : Dictionary
var waiting := false
var last_priority := false
var gui : GUIController


func _ready():
	var proxyPlayers : Array[Player] = [Player.new("Player1"), Player.new("Player2")]
	initialize_game(proxyPlayers)
	start_game()

#handles chaining and priority order in reaction to events
#returns true if gamestate advancement can continue
#returns false if waiting for player input is necessary
func handle_event(event : Event):
	print("handling event %s" % event.event_type)
	var last_priority : Player = event.player
	var player = last_priority
	for player_iter in len(game.players):
		player = game.next_player(player)
		var player_options = get_player_options(player)
		if not options_unapplicable(player_options) and not player in event.deferred_players:
			wait_for_choice(player, Game.GameState.Hot, player_options)
			return false
	if not event.has_resolved and not event.canceled:
		event.resolve(self)
		event.has_resolved = true
		if waiting:
			return false
	else:
		event.handling_finished = true
		return true
	return false

func register_choice(choice : Dictionary):
	waiting = false
	match game.game_state:
		Game.GameState.Cold:
			handle_cold_choice(choice.action)
		Game.GameState.Hot:
			handle_hot_choice(choice)
		_:
			print("Something went wrong: unexpected state in Game Manager register_choice()")

# Handles a registered player decision in the cold state
# Always expects an Action as decision
func handle_cold_choice(decision : Action):
	game.game_state = Game.GameState.Hot
	game.current_turn.turn_actions.append(decision)
	game.hot_action = decision
	handle_action(game.hot_action)

# Handles a registered player decision in the hot state (Chained Event)
# Expects either an Event or Null (Player deferred) as decision
func handle_hot_choice(choice : Dictionary):
	if "type" in choice:
		if choice.type == "activate":
			var event := Event.EffectActivationEvent.new(current_decider, choice.effect)
			game.hot_event.chain_events.append(event)
		if choice.type == "cell":
			pass
		if choice.type == "end_move":
			pass
	if "defer" in choice:
		game.hot_event.deferred_players.append(current_decider)
	handle_action(game.hot_action)

func handle_action(action : Action):
	print("Handling action %s" % str(action))
	game.hot_action = action
	while waiting == false:
		var active_event : Event = action.get_active_event()
		if active_event != null:
			game.hot_event = active_event
			handle_event(active_event)
		else:
			finish_action(action)
			return

func wait_for_choice(decider : Player, gamestate : Game.GameState, options : Dictionary = {default = true}):
	game.game_state = gamestate
	waiting = true
	current_decider = decider
	if "default" in options:
		options = get_player_options(game.current_turn.turn_player)
	current_options = options
	gui.update()

func finish_action(action : Action):
	print("finishing action: %s" % action)
	action.finished = true
	game.hot_action = null
	game.hot_event = null
	wait_for_choice(game.current_turn.turn_player, Game.GameState.Cold)

### Game Initializing

func initialize_game(playerList : Array[Player]):
	game = Game.new(playerList)
	init_field()
	game.init_cards()

func start_game():
	game.start()
	current_decider = game.current_turn.turn_player
	current_options = get_player_options(current_decider)
	waiting = true

func init_field():
	for row in field.fieldpreset.dimensions[0]:
		for column in field.fieldpreset.dimensions[1]:
			var cell = field.fieldpreset.types[row][column]
			if cell[2] != -1:
				var player : Player = game.players[cell[2]]
				if cell[0] == Cell.CellType.Field:
					player.home_cells.append(field.cells[row][column])
				else:
					match cell[1]:
						Cell.StackType.MainDeck:
							player.maindeck_cell = field.cells[row][column]
						Cell.StackType.ResourceDeck:
							player.resourcedeck_cell = field.cells[row][column]
						Cell.StackType.SpecialDeck:
							player.specialdeck_cell = field.cells[row][column]
						Cell.StackType.Graveyard:
							player.graveyard_cell = field.cells[row][column]
						Cell.StackType.Limbo:
							player.limbo_cell = field.cells[row][column]
						Cell.StackType.Banishment:
							player.banishment_cell = field.cells[row][column]

### Option Structure getters

func get_player_options(player : Player):
	var options = {}
	match game.game_state:
		Game.GameState.Cold:
			var turn_option = get_turn_option()
			if player == game.current_turn.turn_player and turn_option != null:
				options.turn_option = turn_option
		Game.GameState.Hot:
			options.decline = {on_click = func(): register_choice({decline = true}), player = player}
	var cardoptions = {}
	for card in player.cards:
		var card_options : Dictionary = get_card_options(card)
		if card_options != {}:
			cardoptions[str(card.id)] = card_options
	if cardoptions != {}:
		options.cardoptions = cardoptions
	return options

func options_unapplicable(options : Dictionary):
	for option_key in options:
		if option_key != "decline":
			return false
	return true

func get_turn_option():
	var turn_action : Action = get_turn_action()
	if turn_action != null:
		var turn_option = {action = turn_action, player = game.current_turn.turn_player}
		turn_option.on_click = func(): register_choice(turn_option)
		turn_option.label = ""
		if turn_action is Action.Draw:
			turn_option.label = "Draw"
		if turn_action is Action.AdvancePhase:
			turn_option.label = "Next Phase"
		if turn_action is Action.EndTurn:
			turn_option.label = "End Turn"
		return turn_option
	return null

func get_turn_action():
	var turn_player : Player = game.current_turn.turn_player
	if game.current_turn.current_phase == Turn.TurnPhase.Draw1 and not game.current_turn.draw1_drawn:
		return Action.Draw.new(turn_player, Card.CardOrigin.ResourceDeck)
	elif game.current_turn.current_phase == Turn.TurnPhase.Draw2 and not game.current_turn.draw2_drawn:
		return Action.Draw.new(turn_player, Card.CardOrigin.MainDeck)
	elif game.current_turn.current_phase == Turn.TurnPhase.Recovery:
		if not game.current_turn.recovery_done:
			return null
	elif game.current_turn.current_phase == Turn.TurnPhase.End:
		return Action.EndTurn.new(turn_player, game.current_turn)
	return Action.AdvancePhase.new(turn_player, game.current_turn.current_phase)

func get_card_options(card : Card):
	var options = {}
	if game.game_state == Game.GameState.Cold:
		var card_action_options : Dictionary = get_card_action_options(card)
		if card_action_options != {}:
			options.actions = card_action_options
	var card_effect_options : Dictionary = get_card_effect_options(card)
	if card_effect_options != {}:
		options.effects = card_effect_options
	return options

#gets called in either state and returns all effect option dicts for the viable effects of a card
func get_card_effect_options(card : Card):
	var options := {}
	for effect in card.effects:
		if effect.condition.call(self, effect):
			var effect_choice = { type = "activate", label = effect.short_text, card = effect.card, effect = effect}
			effect_choice.on_click = func():
				effect_choice.action = Action.EffectActivation.new(card.controller, effect)
				register_choice(effect_choice)
			options[str(effect.id)] = effect_choice
	return options

#only gets called in cold state and returns options dict for all viable actions for a card
func get_card_action_options(card : Card):
	var options := {}
	if card.check_attack_viability(self):
		var attack_choice = { label = "Attack", card = card, player = card.controller, action = Action.Attack.new(card.controller, card)}
		attack_choice.on_click = func() : register_choice(attack_choice)
		options.attack = attack_choice
	if card.check_movement_viability(self):
		var move_choice = { label = "Move", card = card, player = card.controller, action = Action.Move.new(card.controller, card)}
		move_choice.on_click = func() : register_choice(move_choice)
		options.move = move_choice
	if card.check_play_viability(self):
		var play_choice = { label = "Play", card = card, player = card.controller, action = Action.PlayCardFromHand.new(card.card_owner, card) }
		play_choice.on_click = func(): register_choice(play_choice)
		options.play = play_choice
	if card.needs_recovery and game.current_turn.current_phase == Turn.TurnPhase.Recovery:
		var recovery_choice = { label = "Recover", card = card, player = card.controller, action = Action.Recover.new(card.card_owner, card) }
		recovery_choice.on_click = func(): register_choice(recovery_choice)
		options.recover = recovery_choice
	return options

func get_card_option_list(card : Card):
	var options := []
	if "cardoptions" in current_options:
		if str(card.id) in current_options.cardoptions:
			var option_dict : Dictionary = current_options.cardoptions[str(card.id)]
			if "actions" in option_dict:
				for key in option_dict.actions:
					options.append(option_dict.actions[key])
			if "effects" in option_dict:
				for key in option_dict.effects:
					options.append(option_dict.effects[key])
	if "end_move" in current_options:
		if current_options.end_move.card == card:
			options.append(current_options.end_move)
	if "cards" in current_options:
		if str(card.id) in current_options.cards:
			options.append(current_options.cards[str(card.id)])
	return options

func get_cell_option_list(cell : Cell):
	var options := []
	if "cells" in current_options and cell.short_name in current_options.cells:
		return [current_options.cells[cell.short_name]]
	return []
