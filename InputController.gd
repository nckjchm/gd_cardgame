class_name InputController extends Node

signal screen_dragged(mouse_motion)

enum FocusType { Card, Cell, Menu, None }

var cellclicks : Array[Dictionary] = []
var cardclicks : Array[Dictionary] = []
var focused_card : Dictionary = {}
var focused_cell : Dictionary = {}
var focused_menu : Dictionary = {}
var last_focused_card : Dictionary = {}
var last_click_release : InputEventMouseButton
var focus_type : FocusType = FocusType.None
var mouse_relative_motion := Vector2(0,0)
var mouse1_down := false
var mouse1_released := false
@onready var camera : FieldCamera = $"../GameViewContainer/FieldVPC/FieldVP/FieldCamera"
@onready var game_manager : GameManager = $"../GameManager"
var gui : GUIController
var distance_from_mouse_down : Vector2 = Vector2(0,0)

func _ready():
	screen_dragged.connect(camera.move_camera)

func cell_input_event(cell, viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		cellclicks.append({cell = cell, viewport = viewport, event = event, shape_idx = shape_idx})

func card_input_event(card, viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		cardclicks.append({card = card, viewport = viewport, event = event, shape_idx = shape_idx})

func player_click_release():
	var player : Player = game_manager.current_decider
	if distance_from_mouse_down.length() > 30:
		focus_type = FocusType.None
	if not focused_menu.is_empty():
		focus_type = FocusType.Menu
	match focus_type:
		FocusType.Card:
			gui.player_card_click(focused_card.card, player, focused_card.event)
		FocusType.Cell:
			gui.player_cell_click(focused_cell.cell, player, focused_cell.event)
		FocusType.Menu:
			gui.player_menu_click(focused_menu, player)
		FocusType.None:
			gui.player_background_click(player, last_click_release)
		_ :
			("Error in InputController, unknown Focus Type")
	focus_type = FocusType.None
	if focused_card != null:
		last_focused_card = focused_card
	focused_card = {}
	focused_cell = {}
	focused_menu = {}
	distance_from_mouse_down = Vector2(0,0)

func menu_input_event(menu : Control, event : InputEvent, context : Dictionary = {}):
	if event is InputEventMouseButton:
		menu_clicked(menu, context)

func menu_clicked(menu : Control, context : Dictionary = {}):
	focused_menu = {menu = menu, context = context}

func digest_clicked_cards():
	if len(cardclicks) > 0:
		if focused_card == {}:
			focused_card = cardclicks[0]
		focus_type = FocusType.Card
		for entry in cardclicks:
			if entry.card.card.index_in_stack > focused_card.card.card.index_in_stack:
				focused_card = entry
	cardclicks = []

func digest_clicked_cells():
	if len(cellclicks) > 0:
		if focused_cell == {}:
			focused_cell = cellclicks[0]
		if focus_type == FocusType.None:
			focus_type = FocusType.Cell
		for entry in cellclicks:
			if entry.cell.grid_row < focused_cell.cell.grid_row or entry.cell.grid_column < focused_cell.cell.grid_column:
				focused_cell = entry
	cellclicks = []

func _process(delta):
	digest_clicked_cards()
	digest_clicked_cells()
	if mouse1_down:
		screen_dragged.emit(mouse_relative_motion)
	if mouse1_released:
		player_click_release()
	mouse_relative_motion = Vector2(0,0)
	mouse1_released = false

func scroll(factor : float):
	camera.adjust_zoom(factor)

func _input(event):
	if event is InputEventScreenDrag:
		screen_dragged.emit(event.relative)
	if event is InputEventMouseMotion:
		mouse_relative_motion = event.relative
		if mouse1_down:
			distance_from_mouse_down += event.relative
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				mouse1_down = event.pressed
				if not mouse1_down:
					mouse1_released = true
					last_click_release = event
			MOUSE_BUTTON_WHEEL_DOWN:
				scroll(0.9)
			MOUSE_BUTTON_WHEEL_UP:
				scroll(1.1111111)
	if event is InputEventKey:
		match event.keycode:
			KEY_PLUS:
				if event.pressed: scroll(1.1111111)
			KEY_MINUS:
				if event.pressed: scroll(0.9)
		

