extends Node

var rng = RandomNumberGenerator.new()

static func parse_string_array(in_array : Array) -> Array[String]:
	var string_array : Array[String] = []
	string_array.assign(in_array)
	return string_array

func flatten_choices(choices_dict : Dictionary) -> Array[Dictionary]:
	var choice_array : Array[Dictionary] = []
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
	if "alternatives" in choices_dict:
		for alternative_key in choices_dict.alternatives:
			choice_array.append(choices_dict.alternatives[alternative_key])
	return choice_array

func random_color():
	return Color.hex(rng.randi_range(0, 0xffffff) + 0xff000000)
