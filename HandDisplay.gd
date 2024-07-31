class_name HandDisplay extends PanelContainer

@onready var hand_hbox = $ScrollContainer/HandHBox
@onready var gui : GUIController = $"../../../GUIController"
@onready var input_controller : InputController = $"../../../InputController"
@onready var scroll_container : ScrollContainer = $ScrollContainer
var h_scrollbar : HScrollBar

func _ready():
	h_scrollbar = scroll_container.get_h_scroll_bar()
	h_scrollbar.gui_input.connect(_gui_input)
	h_scrollbar.custom_minimum_size = Vector2(0,20)

func empty():
	for child in hand_hbox.get_children():
		child.queue_free()

func refresh_cards(cards : Array[Card]):
	empty()
	for card in cards:
		var card_gui_display = Templates.card_gui_diplay_prefab.instantiate()
		card_gui_display.initialize(card, gui)
		var frame := Container.new()
		frame.custom_minimum_size = Vector2(300, 400)
		hand_hbox.add_child(frame)
		frame.add_child(card_gui_display)

func _gui_input(event):
	input_controller.menu_input_event(self, event, {})
