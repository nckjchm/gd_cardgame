class_name Deck

var name : String
var main_deck : Array[Card] = []
var resource_deck : Array[Card] = []
var special_deck : Array[Card] = []
var deck_template : DeckTemplate

func _init(deck_template, name : String = ""):
	self.deck_template = deck_template
	self.name = name if name != "" else deck_template.name
	
