extends Node

var templates = {
	YlwCrtFarmer = CardTemplate.YlwCrtFarmer.new(),
	YlwLndAcre = CardTemplate.YlwLndAcre.new(),
	YlwCrtGuy = CardTemplate.YlwCrtGuy.new(),
	YlwCrtDude = CardTemplate.YlwCrtDude.new(),
	YlwCrtAttacker = CardTemplate.YlwCrtAttacker.new(),
	YlwLndOrchard = CardTemplate.YlwLndOrchard.new(),
	YlwStrSchool = CardTemplate.YlwStrSchool.new()
}
var card_prefab = preload("res://card.tscn")
var card_gui_diplay_prefab = preload("res://card_gui_display.tscn")

var deck_templates = { 
	TestDeckYellow = DeckTemplate.TestDeckYellow.new()
}

var field_templates = {
	small_two_player_field1 = small_two_player_field1_template
}

const fieldcell = [Cell.CellType.Field, Cell.StackType.None, -1]
const player1_home = [Cell.CellType.Field, Cell.StackType.None, 0]
const player2_home = [Cell.CellType.Field, Cell.StackType.None, 1]
const emptycell = [Cell.CellType.Inactive, Cell.StackType.None, -1]

const small_two_player_field1_template := {
	"dimensions" : [9, 9],
	"seats" : {
		count = 2,
		rotations = [ 180.0, 0.0 ]
	},
	"types" : [
		[
			[Cell.CellType.Stack, Cell.StackType.Graveyard, 0], 
			[Cell.CellType.Stack, Cell.StackType.MainDeck, 0],
			player1_home, player1_home, player1_home, player1_home, player1_home, 
			[Cell.CellType.Stack, Cell.StackType.ResourceDeck, 0],
			[Cell.CellType.Stack, Cell.StackType.SpecialDeck, 0]
		],
		[
			emptycell, [Cell.CellType.Stack, Cell.StackType.Limbo, 0],
			fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell,
			[Cell.CellType.Stack, Cell.StackType.Banishment, 0]
		],
		[ emptycell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, emptycell ],
		[ emptycell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell ],
		[ fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell ],
		[ emptycell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell ],
		[ emptycell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, emptycell ],
		[
			emptycell, [Cell.CellType.Stack, Cell.StackType.Banishment, 1],
			fieldcell, fieldcell, fieldcell, fieldcell, fieldcell, fieldcell,
			[Cell.CellType.Stack, Cell.StackType.Limbo, 1]
		],
		[
			[Cell.CellType.Stack, Cell.StackType.SpecialDeck, 1],
			[Cell.CellType.Stack, Cell.StackType.ResourceDeck, 1],
			player2_home, player2_home, player2_home, player2_home, player2_home,
			[Cell.CellType.Stack, Cell.StackType.MainDeck, 1],
			[Cell.CellType.Stack, Cell.StackType.Graveyard, 1]
		]
	]
}
