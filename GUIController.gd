class_name GUIController extends Node

var card_menu_open := false
var card_menu : CardMenu = null
var card_menu_prefab = preload("res://card_menu.tscn")
var cell_menu_open := false
var cell_menu : CellMenu = null
var cell_menu_prefab = preload("res://cell_menu.tscn")
var all_choices_menu_open := false
var all_choices_menu : AllChoicesMenu = null
var all_choices_menu_prefab = preload("res://all_choices_menu.tscn")
@onready var game_manager : GameManager = $"../GameManager"
@onready var btn_pass_phase : Button = $"../GameViewContainer/SideGUI/SideGUIBoxContainer/PassPhaseButton"
@onready var btn_draw : Button = $"../GameViewContainer/SideGUI/SideGUIBoxContainer/DrawButton"
@onready var btn_decline : Button = $"../GameViewContainer/SideGUI/SideGUIBoxContainer/DeclineButton"
@onready var btn_recover : Button = $"../GameViewContainer/SideGUI/SideGUIBoxContainer/RecoverButton"
@onready var btn_all_choices : Button = $"../GameViewContainer/SideGUI/SideGUIBoxContainer/AllChoicesButton"
@onready var main_control : Control = $".."
@onready var turn_phase_display : Label = $"../GameViewContainer/SideGUI/SideGUIBoxContainer/HBoxContainer/TurnPhaseText"
@onready var hand : HandDisplay = $"../GameViewContainer/FieldVPC/FieldVP/HandCanvas/HandPanel"

func click_to_close():
	if card_menu_open or cell_menu_open:
		close_cell_menu()
		close_card_menu()
		return true
	return false

func update_buttons():
	var options = game_manager.current_options
	var buttons : Array[Button] = [btn_pass_phase, btn_draw, btn_decline, btn_recover]
	btn_pass_phase.text = "Pass Phase"
	for button in buttons:
		button.disabled = true
		for connection in button.pressed.get_connections():
			button.pressed.disconnect(connection.callable)
	btn_all_choices.disabled = false
	if game_manager.local_player != game_manager.current_decider:
		btn_all_choices.disabled = true
		return
	if "turn_option" in options:
		if options.turn_option.action is Action.Draw:
			btn_draw.disabled = false
			btn_draw.pressed.connect(options.turn_option.on_click)
		elif options.turn_option.action is Action.AdvancePhase:
			btn_pass_phase.disabled = false
			btn_pass_phase.text = "Next Phase"
			btn_pass_phase.pressed.connect(options.turn_option.on_click)
		elif options.turn_option.action is Action.EndTurn:
			btn_pass_phase.disabled = false
			btn_pass_phase.text = "End Turn"
			btn_pass_phase.pressed.connect(options.turn_option.on_click)
	

#{ Start, Recovery, Draw1, Main1, Battle, Draw2, Main2, End }
func update():
	print("updating gui")
	update_buttons()
	update_turndisplay()
	if not game_manager.game.game_state in [Game.GameState.Preparation, Game.GameState.Paused]:
		hand.refresh_cards(game_manager.local_player.hand.cards)

func _ready():
	game_manager.gui = self
	game_manager.input_controller.gui = self
	btn_all_choices.pressed.connect(func(): open_all_choices_menu(game_manager.current_options))
	update()

func close_card_menu():
	if card_menu_open:
		card_menu.queue_free()
		card_menu_open = false
		card_menu = null

func close_cell_menu():
	if cell_menu_open:
		cell_menu.queue_free()
		cell_menu_open = false
		cell_menu = null

func close_all_choices_menu():
	if all_choices_menu_open:
		all_choices_menu.queue_free()
		all_choices_menu_open = false
		all_choices_menu = null

func open_all_choices_menu(options : Dictionary):
	close_all_choices_menu()
	all_choices_menu = all_choices_menu_prefab.instantiate()
	all_choices_menu.initialize(self, game_manager.current_options, func(): close_all_choices_menu())
	all_choices_menu_open = true
	main_control.add_child(all_choices_menu)

func open_card_menu(card : Card, position : Vector2):
	card_menu = card_menu_prefab.instantiate()
	card_menu.choices = game_manager.get_card_option_list(card)
	card_menu.card = card
	card_menu_open = true
	main_control.add_child(card_menu)
	card_menu.position = position

func open_cell_menu(cell : Cell, position : Vector2):
	cell_menu = cell_menu_prefab.instantiate()
	cell_menu.choices = game_manager.get_cell_option_list(cell)
	cell_menu_open = true
	cell_menu.gui = self
	cell_menu.cell = cell
	main_control.add_child(cell_menu)
	cell_menu.position = position

func player_card_click(card_display : CardDisplay, _player : Player, click_event : InputEventMouseButton):
	if not click_to_close():
		open_card_menu(card_display.card, click_event.global_position)

func player_cell_click(cell : Cell, _player : Player, click_event : InputEventMouseButton):
	if not click_to_close():
		open_cell_menu(cell, click_event.global_position)

func player_background_click(_player : Player, click_event: InputEventMouseButton):
	click_to_close()

func update_turndisplay():
	var turn_phase_text = ""
	if not game_manager.game.game_state in [Game.GameState.Paused, Game.GameState.Preparation]:
		match game_manager.game.current_turn.current_phase:
			Turn.TurnPhase.Start:
				turn_phase_text = "Start Phase"
			Turn.TurnPhase.Recovery:
				turn_phase_text = "Recovery Phase"
			Turn.TurnPhase.Draw1:
				turn_phase_text = "Draw Phase 1"
			Turn.TurnPhase.Main1:
				turn_phase_text = "Main Phase 1"
			Turn.TurnPhase.Battle:
				turn_phase_text = "Battle Phase"
			Turn.TurnPhase.Draw2:
				turn_phase_text = "Draw Phase 2"
			Turn.TurnPhase.Main2:
				turn_phase_text = "Main Phase 2"
			Turn.TurnPhase.End:
				turn_phase_text = "End Phase"
	turn_phase_display.text = turn_phase_text

func refresh_hand(player : Player):
	hand.refresh_cards(player.hand.cards)
