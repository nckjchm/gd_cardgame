class_name Player

var name : String
var deck : Deck
var seat : int
var hand : Hand
var cards : Array
var maindeck_cell : Cell
var resourcedeck_cell : Cell
var specialdeck_cell : Cell
var graveyard_cell : Cell
var limbo_cell : Cell
var banishment_cell : Cell
var home_cells : Array[Cell] = []
var resources : ResourceList
var rotation : float
var session_id : int

func _init(name : String):
	self.name = name
	initialize_deck()
	
func initialize_deck(deck_name : String = "Yellow"):
	match deck_name:
		"Yellow":
			deck = Deck.new(DeckTemplate.TestDeckYellow.new(), "Testdeck Yellow")
