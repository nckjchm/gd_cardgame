class_name InputController extends Node

signal screen_dragged(mouse_motion)

enum FocusType { Card, Cell, None }

var cellclicks : Array[Dictionary] = []
var cardclicks : Array[Dictionary] = []
var focused_card : Dictionary = {}
var focused_cell : Dictionary = {}
var last_focused_card : Dictionary = {}
var last_click_release : InputEventMouseButton
var focus_type : FocusType = FocusType.None
var mouse_relative_motion := Vector2(0,0)
var mouse1_down := false
var mouse1_released := false
@onready var camera : FieldCamera = $"../GameViewContainer/FieldVPC/FieldVP/FieldCamera"
@onready var game_manager : GameManager = $"../GameManager"
var gui : GUIController

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
	match focus_type:
		FocusType.Card:
			gui.player_card_click(focused_card.card, player, focused_card.event)
		FocusType.Cell:
			gui.player_cell_click(focused_cell.cell, player, focused_cell.event)
		FocusType.None:
			gui.player_background_click(player, last_click_release)
		_ :
			("Error in InputController, unknown Focus Type")
	focus_type = FocusType.None
	if focused_card != null:
		last_focused_card = focused_card
	focused_card = {}
	focused_cell = {}

func digest_clicked_cards():
	if len(cardclicks) > 0:
		if focused_card == {}:
			focused_card = cardclicks[0]
		focus_type = FocusType.Card
		for entry in cardclicks:
			if entry.card.index_in_stack > focused_card.card.index_in_stack:
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

func _input(event):
	if event is InputEventScreenDrag:
		print("Screen dragged")
		screen_dragged.emit(event.relative)
	if event is InputEventMouseMotion:
		mouse_relative_motion = event.relative
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse1_down = event.pressed
			if not mouse1_down:
				mouse1_released = true
				last_click_release = event

