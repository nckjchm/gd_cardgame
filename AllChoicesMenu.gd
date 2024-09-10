class_name AllChoicesMenu extends PanelContainer

var choices : Array[Dictionary] = []
var exit : Callable
var gui : GUIController
@export var close_on_choice := false
const GRID_ROWS := 7
@onready var option_grid : GridContainer = $MenuVBC/OptionGrid
@onready var exit_button : Button = $MenuVBC/Button

func initialize(_gui : GUIController, _exit : Callable):
	exit = _exit
	gui = _gui

func update_choices():
	clear()
	for choice in GameUtil.flatten_choices(gui.game_manager.current_options):
		choices.append({
			type = choice.type,
			text = choice.label,
			player = choice.player if "player" in choice else null,
			card = choice.card if "card" in choice else null,
			cell = choice.cell if "cell" in choice else null,
			effect = choice.effect if "effect" in choice else null,
			choose = choice.on_click
		})
	for choice in choices:
		new_row(choice)

func new_row(choice : Dictionary):
	var row_type : Label = Label.new()
	row_type.text = choice.type
	var row_text : Label = Label.new()
	if choice.text != null:
		row_text.text = choice.text
	var row_player : Label = Label.new()
	if choice.player != null:
		row_player.text = choice.player.name
	var row_card : Label = Label.new()
	if choice.card != null:
		row_card.text = str(choice.card.id)
	var row_cell : Label = Label.new()
	if choice.cell != null:
		row_cell.text = choice.cell.short_name
	var row_effect : Label = Label.new()
	if choice.effect != null:
		row_effect.text = str(choice.effect.id)
	var row_choose_button : Button = Button.new()
	row_choose_button.pressed.connect(func():
		choice.choose.call()
		if close_on_choice:
			gui.close_all_choices_menu()
	)
	row_choose_button.text = "X"
	var row : Array[Control] = [row_type, row_text, row_player, row_card, row_cell, row_effect, row_choose_button]
	for element in row:
		option_grid.add_child(element)

func clear():
	choices = []
	for grid_element in option_grid.get_children():
		if grid_element.get_index() >= GRID_ROWS:
			grid_element.queue_free()

func _ready():
	exit_button.pressed.connect(exit)
	update_choices()
