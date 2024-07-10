class_name HandDisplay extends PanelContainer

@onready var hand_hbox = $HandHBox

func empty():
	for child in hand_hbox.get_children():
		hand_hbox.remove_child(child)

func refresh_cards(cards : Array[Card]):
	empty()
	for card in cards:
		hand_hbox.add_child(card)
		card.position = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
