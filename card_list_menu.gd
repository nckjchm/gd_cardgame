class_name CardListMenu extends PanelContainer

var cards : Array[Card]
var gui : GUIController
@onready var btn_exit : Button = $Body/Footer/Exit
@onready var content : HBoxContainer = $Body/ScrollContainer/Content
@onready var input_controller : InputController = $/root/Main/Game/InputController
@onready var scroll_container : ScrollContainer = $Body/ScrollContainer
var h_scrollbar : HScrollBar

func initialize(cards : Array[Card], gui : GUIController):
	self.cards = cards
	self.gui = gui
	print("opening card list menu")

func _ready():
	btn_exit.pressed.connect(func():
		gui.close_card_list_menu()
	)
	h_scrollbar = scroll_container.get_h_scroll_bar()
	h_scrollbar.gui_input.connect(_gui_input)
	redraw_cards()

func redraw_cards():
	for child in content.get_children():
		child.queue_free()
	if cards.is_empty():
		var standin = Label.new()
		standin.text = "No Cards in this List"
		var frame := Container.new()
		frame.custom_minimum_size = Vector2(300, 420)
		frame.add_child(standin)
		content.add_child(frame)
	for card in cards:
		var card_display : CardDisplay = card.create_card_display()
		var frame := Container.new()
		frame.custom_minimum_size = Vector2(300, 400)
		frame.add_child(card_display)
		content.add_child(frame)
		card_display.position = Vector2(150, 200)

func _gui_input(event):
	input_controller.menu_input_event(self, event, {})
