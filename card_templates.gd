extends Node

var templates = {
	YlwCrtFarmer = YlwCrtFarmer.new(),
	YlwLndAcre = YlwLndAcre.new()
}
var card_prefab = preload("res://card.tscn")

class YlwCrtFarmer extends CardTemplate:
	func _init():
		name = "Farmer"
		card_color = Card.CardColor.Yellow
		type = Card.CardType.Creature
		cost = ResourceList.new([
			ResourceList.ResourceElement.new(ResourceList.ResourceKind.Mana, Card.CardColor.Yellow, 1)
		])
		health = 1
		defense = 0
		attack = 1
		speed = 2
		play_cell_scope= func(card : Card, gm : GameManager): return def_play_cell_scope(card, gm)
		play_condition = func(card : Card, gm : GameManager): return true

class YlwLndAcre extends CardTemplate:
	func _init():
		name = "Acre"
		card_color = Card.CardColor.Yellow
		type = Card.CardType.Land
		cost = ResourceList.new()
		health = 0
		defense = 0
		attack = 0
		speed = 0
		effects = [
			EffectTemplate.ETGain1YellowMana.new()
		]
		play_cell_scope = func(card : Card, gm : GameManager): return def_land_play_cell_scope(card, gm)
		play_condition = func(card : Card, gm : GameManager): return len(def_land_play_cell_scope(card, gm)) > 0
