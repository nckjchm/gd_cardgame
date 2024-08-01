class_name CardListMenu extends PanelContainer

signal card_list_menu_input_event(card_menu : Control, event : InputEvent, context : Dictionary)

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

func _ready():
	card_list_menu_input_event.connect(input_controller.menu_input_event)
	btn_exit.pressed.connect(func():
		gui.close_card_list_menu()
	)
	h_scrollbar = scroll_container.get_h_scroll_bar()
	h_scrollbar.gui_input.connect(_gui_input)
	h_scrollbar
	redraw_cards()

func redraw_cards():
	for child in content.get_children():
		child.queue_free()
	if cards.is_empty():
		var standin = Label.new()
		standin.text = "No Cards in this List"
		var frame := Container.new()
		frame.custom_minimum_size = Vector2(300, 400)
		frame.add_child(standin)
		content.add_child(frame)
	for card in cards:
		var card_gui_display : CardGUIDisplay = Templates.card_gui_display_prefab.instantiate()
		card_gui_display.initialize(card, gui)
		var frame := Container.new()
		frame.custom_minimum_size = Vector2(300, 400)
		content.add_child(frame)
		frame.add_child(card_gui_display)

func _gui_input(event):
	card_list_menu_input_event.emit(self, event, {})
