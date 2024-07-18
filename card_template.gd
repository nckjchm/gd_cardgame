class_name CardTemplate

var name : String
var type : Card.CardType
var cost : ResourceList
var card_color : Card.CardColor
var health : int
var defense : int
var attack : int
var speed : int
var can_coexist := false
var play_condition : Callable
var play_cell_scope : Callable
var effects : Array[EffectTemplate] = []

func def_land_play_cell_scope(card : Card, gm : GameManager):
	var cells : Array[Cell] = gm.field.get_cells_in_distance(card.card_owner.home_cells, 1, false)
	cells.filter(func(cell : Cell):
		if len(cell.cards) > 0:
			return false
		if cell not in card.card_owner.home_cells:
			var has_neighbor_land := false
			var neighbors = gm.field.get_neighbor_cells(cell)
			for neighbor in neighbors:
				for neighbor_card in neighbor.cards:
					if neighbor_card.card_type == Card.CardType.Land:
						has_neighbor_land = true
			if not has_neighbor_land:
				return false
		return true
	)
	return cells

func def_play_cell_scope(card : Card, gm : GameManager):
	var cells : Array[Cell] = gm.field.get_cells_in_distance(card.card_owner.home_cells, 2, false)
	cells = cells.filter(func(cell : Cell):
		for cell_card in cell.cards:
			if cell_card.card_type in [Card.CardType.Creature, Card.CardType.Structure]:
				return false
		if cell not in card.card_owner.home_cells:
			var has_neighbor_land := false
			var neighbors = gm.field.get_neighbor_cells(cell)
			for neighbor in neighbors:
				for neighbor_card in neighbor.cards:
					if neighbor_card.card_type == Card.CardType.Land:
						has_neighbor_land = true
			if not has_neighbor_land:
				return false
		return true
	)
	return cells
