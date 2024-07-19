class_name AllChoicesMenu extends PanelContainer

var choices : Array[Dictionary] = []
var choices_dict : Dictionary = {}
var initialized := false
var readied := false
var exit : Callable
var gui : GUIController
@onready var option_grid : GridContainer = $MenuVBC/OptionGrid
@onready var exit_button : Button = $MenuVBC/Button


func initialize(controller : GUIController, current_choices : Dictionary, exit : Callable):
	self.exit = exit
	gui = controller
	choices_dict = current_choices
	parse_choices()
	initialized = true
	finish()

func parse_choices():
	if "turn_option" in choices_dict:
		if choices_dict.turn_option != null:
			choices.append({
				type = choices_dict.turn_option.label,
				text = null,
				player = choices_dict.turn_option.player,
				card = null,
				cell = null,
				effect = null,
				choose = choices_dict.turn_option.on_click
			})
	if "decline" in choices_dict:
		choices.append({
			type = "Decline",
			text = null,
			player = choices_dict.decline.player,
			card = null,
			cell = null,
			effect = null,
			choose = choices_dict.decline.on_click
		})
	if "cardoptions" in choices_dict:
		for card_id_str in choices_dict.cardoptions:
			var cardoptions = choices_dict.cardoptions[card_id_str]
			if "actions" in cardoptions:
				for actionoption_key in cardoptions.actions:
					var actionoption = cardoptions.actions[actionoption_key]
					choices.append({
						type = actionoption.label,
						text = null,
						player = actionoption.player,
						card = actionoption.card,
						cell = null,
						effect = null,
						choose = actionoption.on_click
					})
			if "effects" in cardoptions:
				for effectoption_key in cardoptions.effects:
					var effectoption = cardoptions.effects[effectoption_key]
					choices.append({
						type = "Effect",
						text = effectoption.label,
						player = effectoption.player if "player" in effectoption else null,
						card = effectoption.card,
						cell = null,
						effect = null,
						choose = effectoption.on_click
					})
	if "cells" in choices_dict:
		for cell_key in choices_dict.cells:
			var celloption = choices_dict.cells[cell_key]
			choices.append({
				type = celloption.type,
				text = celloption.label,
				player = null,
				card = null,
				cell = celloption.cell,
				effect = null,
				choose = celloption.on_click
			})
	if "cards" in choices_dict:
		for card_key in choices_dict.cards:
			var cardoption = choices_dict.cards[card_key]
			choices.append({
				type = cardoption.type,
				text = cardoption.label,
				player = null,
				card = cardoption.card,
				cell = cardoption.card.cell,
				effect = null,
				choose = cardoption.on_click
			})
	if "end_move" in choices_dict:
		var optiondict = choices_dict.end_move
		choices.append({
			type = optiondict.type,
			text = null,
			player = null,
			card = null,
			cell = null,
			effect = null,
			choose = optiondict.on_click
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
		row_cell.text = "Row %d Column %d" % [choice.cell.grid_row, choice.cell.grid_column]
	var row_effect : Label = Label.new()
	if choice.effect != null:
		row_effect.text = str(choice.effect.id)
	var row_choose_button : Button = Button.new()
	row_choose_button.pressed.connect(func():
		choice.choose.call()
		gui.close_all_choices_menu()
	)
	row_choose_button.text = "X"
	var new_row : Array[Control] = [row_type, row_text, row_player, row_card, row_cell, row_effect, row_choose_button]
	for element in new_row:
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

func _process(delta):
	pass
