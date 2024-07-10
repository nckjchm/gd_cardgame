class_name CardEffect

var card : Card
var condition : Callable
var activate : Callable
var template : EffectTemplate
var long_text : String
var short_text : String
var id : int

func _init(template : EffectTemplate, card : Card, id : int):
	self.template = template
	self.id = id
	self.card = card
	condition = template.condition
	activate = template.activate
	long_text = template.long_text
	short_text = template.short_text

class CardScope:
	var name_contains = null
	var name_doesnt_contain = null
	var name_exact = null
	var name_not_exact = null
	var color_in = null
	var color_not_in = null
	var cost_contains = null
	var cost_doesnt_contain = null
	var cost_exact = null
	var cost_total = null
	var cell_in = null
	var cell_not_in = null
	var tap_status_in = null
	var owner_in = null
	var owner_not_in = null
	var controller_in = null
	var controller_not_in = null
	
	
	func get_viable_targets(gm : GameManager):
		var viable_targets = []
		for player in gm.game.players:
			for card in player.cards:
				if check_target_viability(card):
					viable_targets.append(card)
		return viable_targets
	
	func check_target_viability(card : Card):
		if name_contains != null and not card.name.contains(name_contains):
			return false
		if name_doesnt_contain != null and card.name.contains(name_doesnt_contain):
			return false
		if name_exact != null and card.name != name_exact:
			return false
		if name_not_exact != null and card.name == name_not_exact:
			return false
		if color_in != null and not card.card_color in color_in:
			return false
		if color_not_in != null and card.card_color in color_not_in:
			return false
		if cost_contains != null and not card.cost.check_coverage(cost_contains):
			return false
		if cost_doesnt_contain != null and card.cost.check_coverage(cost_doesnt_contain):
			return false
		if cost_exact != null and not card.cost.check_coverage(cost_exact, true):
			return false
		if cost_total != null and card.cost.total() != cost_total:
			return false
		if cell_in != null and not card.cell in cell_in:
			return false
		if cell_not_in != null and card.cell in cell_not_in:
			return false
		if tap_status_in != null and not card.tap_status in tap_status_in:
			return false
		if owner_in != null and not card.owner in owner_in:
			return false
		if owner_not_in != null and card.owner in owner_not_in:
			return false
		if controller_in != null and not card.controller in controller_in:
			return false
		if controller_not_in != null and card.controller in controller_not_in:
			return false
		return true
