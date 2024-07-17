class_name HandDisplay extends PanelContainer

@onready var hand_hbox = $HandHBox

func empty():
	for child in hand_hbox.get_children():
		for grandchild in child.get_children():
			child.remove_child(grandchild)
		hand_hbox.remove_child(child)

func refresh_cards(cards : Array[Card]):
	empty()
	var cardwidth := 300
	for card in cards:
		var card_container := MarginContainer.new()
		card_container.custom_minimum_size = Vector2(cardwidth, 0)
		card_container.add_child(card)
		hand_hbox.add_child(card_container)
		card.position = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
