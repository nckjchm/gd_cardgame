class_name AllChoicesMenu extends PanelContainer

var choices : Array[Dictionary] = []
var choices_dict : Dictionary = {}
var initialized := false
var readied := false
var exit : Callable
var gui : GUIController
@onready var option_grid : GridContainer = $MenuVBC/OptionGrid
@onready var exit_button : Button = $MenuVBC/Button


func initialize(_gui : GUIController, current_choices : Dictionary, _exit : Callable):
	exit = _exit
	gui = _gui
	choices_dict = current_choices
	parse_choices()
	initialized = true
	finish()

func parse_choices():
	var choice_array := []
	if "turn_option" in choices_dict:
		choice_array.append(choices_dict.turn_option)
	if "decline" in choices_dict:
		choice_array.append(choices_dict.decline)
	if "cardoptions" in choices_dict:
		for card_id_str in choices_dict.cardoptions:
			var cardoptions = choices_dict.cardoptions[card_id_str]
			if "actions" in cardoptions:
				for actionoption_key in cardoptions.actions:
					choice_array.append(cardoptions.actions[actionoption_key])
			if "effects" in cardoptions:
				for effectoption_key in cardoptions.effects:
					choice_array.append(cardoptions.effects[effectoption_key])
	if "cells" in choices_dict:
		for cell_key in choices_dict.cells:
			choice_array.append(choices_dict.cells[cell_key])
	if "cards" in choices_dict:
		for card_key in choices_dict.cards:
			choice_array.append(choices_dict.cards[card_key])
	if "end_move" in choices_dict:
		choice_array.append(choices_dict.end_move)
	for choice in choice_array:
		choices.append({
			type = choice.type,
			text = choice.label,
			player = choice.player if "player" in choice else null,
			card = choice.card if "card" in choice else null,
			cell = choice.cell if "cell" in choice else null,
			effect = choice.effect if "effect" in choice else null,
			choose = choice.on_click
		})

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
		gui.close_all_choices_menu()
	)
	row_choose_button.text = "X"
	var row : Array[Control] = [row_type, row_text, row_player, row_card, row_cell, row_effect, row_choose_button]
	for element in row:
		option_grid.add_child(element)
	
func finish():
	if not initialized or not readied:
		return
	exit_button.pressed.connect(exit)
	for choice in choices:
		new_row(choice)

func _ready():
	readied = true
	finish()
