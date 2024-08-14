class_name CardGUIDisplay extends Control

signal gui_card_input_event(card_gui: CardGUIDisplay, event : InputEvent)

var card_display : CardDisplay
var is_ready := false
var is_initialized := false
var gui : GUIController

func initialize(card : Card, _gui : GUIController):
	card_display = card.create_card_display()
	card_display.gui_embedded = true
	gui = _gui
	is_initialized = true
	update()

func from_template(template : CardTemplate):
	card_display = Templates.card_prefab.instantiate()
	card_display.from_template(template)
	is_initialized = true
	update()

func _ready():
	is_ready = true
	update()

func update():
	#gui_card_input_event.connect(gui.game_manager.input_controller.card_gui_input_event)
	for connected in card_display.card_input_event.get_connections():
		card_display.card_input_event.disconnect(connected)
	if not is_ready or not is_initialized:
		return
	add_child(card_display)
	card_display.position = custom_minimum_size / 2
	gui_input.connect(func (event):
		gui_card_input_event.emit(self, event)
	)

func _get_drag_data(at_position):
	pass
	
func _can_drop_data(at_position, data):
	return false

func _drop_data(at_position, data):
	pass
