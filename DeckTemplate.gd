class_name DeckTemplate

var name : String
var main_deck_keys : Array[String]
var resource_deck_keys : Array[String]
var special_deck_keys : Array[String]

func _init(_name : String, main_deck : Array[String], resource_deck : Array[String], special_deck : Array[String]):
	name = _name
	main_deck_keys = main_deck
	resource_deck_keys = resource_deck
	special_deck_keys = special_deck

static func from_serialized(data : Dictionary):
	return DeckTemplate.new(
		data.name, 
		GameUtil.parse_string_array(data.main), 
		GameUtil.parse_string_array(data.resource), 
		GameUtil.parse_string_array(data.special)
	)

class TestDeckYellow extends DeckTemplate:
	func _init():
		super._init("Testdeck Yellow",
			["YlwCrtFarmer", "YlwCrtFarmer", "YlwCrtFarmer", "YlwCrtGuy", "YlwCrtGuy", "YlwCrtGuy", "YlwCrtDude", "YlwCrtDude", "YlwCrtDude", "YlwCrtAttacker", "YlwCrtAttacker", "YlwStrSchool", "YlwStrSchool"],
			["YlwLndAcre", "YlwLndOrchard", "YlwLndAcre", "YlwLndAcre", "YlwLndAcre", "YlwLndAcre", "YlwLndAcre"],
			[])
