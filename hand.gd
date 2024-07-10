class_name Hand

var cards : Array[Card]
var player : Player

func _init(player : Player):
	self.player = player
	cards = []

func add_card(card):
	cards.append(card)

func remove_card(card):
	if card in cards:
		cards.erase(card)
