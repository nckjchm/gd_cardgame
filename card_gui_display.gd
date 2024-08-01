class_name CardGUIDisplay extends Control

signal gui_card_input_event(card_gui: CardGUIDisplay, event : InputEvent)

var card_display : CardDisplay
var is_ready := false
var is_initialized := false
var gui : GUIController

func initialize(card : Card, gui : GUIController):
	card_display = card.create_card_display()
	self.gui = gui
	is_initialized = true
	update()

func _ready():
	is_ready = true
	update()

func update():
	gui_card_input_event.connect(gui.game_manager.input_controller.card_gui_input_event)
	for connected in card_display.card_input_event.get_connections():
		card_display.card_input_event.disconnect(connected)
	if not is_ready or not is_initialized:
		return
	add_child(card_display)
	card_display.position = custom_minimum_size / 2
	gui_input.connect(func (event):
		gui_card_input_event.emit(self, event)
	)
