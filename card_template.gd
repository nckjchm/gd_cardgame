class_name CardTemplate

var name : String
var type : Card.CardType
var cost : ResourceList
var card_color : Card.CardColor
var card_aspects : Array[Card.CardAspect]
var health : int
var defense : int
var attack : int
var speed : int
var can_coexist := false
var play_condition : Callable
var play_cell_scope : Callable
var effects : Array[EffectTemplate] = []

class YlwCrtFarmer extends CardTemplate:
	func _init():
		name = "Farmer"
		card_color = Card.CardColor.Yellow
		type = Card.CardType.Creature
		cost = ResourceList.new([
			ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 1)
		])
		card_aspects = [Card.CardAspect.Humanoid]
		health = 2
		defense = 0
		attack = 3
		speed = 2
		play_cell_scope= func(card : Card, gm : GameManager): return def_play_cell_scope(card, gm)
		play_condition = func(card : Card, gm : GameManager): return def_play_condition(card, gm)

class YlwLndAcre extends CardTemplate:
	func _init():
		name = "Acre"
		card_color = Card.CardColor.Yellow
		type = Card.CardType.Land
		cost = ResourceList.new()
		card_aspects = [Card.CardAspect.Land]
		health = 0
		defense = 0
		attack = 0
		speed = 0
		can_coexist = true
		effects = [
			EffectTemplate.ETGain1YellowMana.new()
		]
		play_cell_scope = func(card : Card, gm : GameManager): return def_land_play_cell_scope(card, gm)
		play_condition = func(card : Card, gm : GameManager): return def_play_condition(card, gm)

class YlwCrtGuy extends CardTemplate:
	func _init():
		name = "Guy"
		card_color = Card.CardColor.Yellow
		type = Card.CardType.Creature
		cost = ResourceList.new([
			ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 2)
		])
		card_aspects = [Card.CardAspect.Humanoid]
		health = 4
		defense = 1
		attack = 3
		speed = 2
		play_cell_scope= func(card : Card, gm : GameManager): return def_play_cell_scope(card, gm)
		play_condition = func(card : Card, gm : GameManager): return def_play_condition(card, gm)

class YlwCrtDude extends CardTemplate:
	func _init():
		name = "Dude"
		card_color = Card.CardColor.Yellow
		type = Card.CardType.Creature
		cost = ResourceList.new([
			ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 3)
		])
		card_aspects = [Card.CardAspect.Humanoid]
		health = 5
		defense = 1
		attack = 4
		speed = 2
		play_cell_scope= func(card : Card, gm : GameManager): return def_play_cell_scope(card, gm)
		play_condition = func(card : Card, gm : GameManager): return def_play_condition(card, gm)

class YlwCrtAttacker extends CardTemplate:
	func _init():
		name = "Attacker"
		card_color = Card.CardColor.Yellow
		type = Card.CardType.Creature
		cost = ResourceList.new([
			ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 4)
		])
		card_aspects = [Card.CardAspect.Humanoid]
		health = 7
		defense = 0
		attack = 5
		speed = 3
		play_cell_scope= func(card : Card, gm : GameManager): return def_play_cell_scope(card, gm)
		play_condition = func(card : Card, gm : GameManager): return def_play_condition(card, gm)

func def_play_condition(card : Card, gm : GameManager):
	if not gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]:
		return false
	if play_cell_scope.call(card, gm).is_empty():
		return false
	return true

func def_land_play_cell_scope(card : Card, gm : GameManager):
	var cells : Array[Cell] = gm.field.get_cells_in_distance(card.card_owner.home_cells, 1, false)
	cells = cells.filter(func(cell : Cell):
		for cell_card in cell.cards:
			if not cell_card.can_coexist:
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
	var cells : Array[Cell] = gm.field.get_cells_in_distance(card.card_owner.home_cells, 0, false)
	cells = cells.filter(func(cell : Cell):
		for cell_card in cell.cards:
			if not cell_card.can_coexist:
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
