class_name DeckTemplate

var name : String
var main_deck_keys : Array[String]
var resource_deck_keys : Array[String]
var special_deck_keys : Array[String]

func _init(name : String, main_deck : Array[String], resource_deck : Array[String], special_deck : Array[String]):
	self.name = name
	self.main_deck_keys = main_deck
	self.resource_deck_keys = resource_deck
	self.special_deck_keys = special_deck

class TestDeckYellow extends DeckTemplate:
	func _init():
		super._init("Testdeck Yellow",
			["YlwCrtFarmer", "YlwCrtFarmer", "YlwCrtFarmer", "YlwCrtGuy", "YlwCrtGuy", "YlwCrtGuy", "YlwCrtDude", "YlwCrtDude", "YlwCrtDude", "YlwCrtAttacker"],
			["YlwLndAcre", "YlwLndAcre", "YlwLndAcre", "YlwLndAcre", "YlwLndAcre", "YlwLndAcre", "YlwLndAcre"],
			[])
