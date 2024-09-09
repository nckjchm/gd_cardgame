class_name CardGUIDisplay extends Control

signal gui_card_input_event(card_gui: CardGUIDisplay, event : InputEvent)
signal data_drop_received(recipient: CardGUIDisplay, data)
signal drag_started(dragged_card: CardGUIDisplay)

var card_display : CardDisplay
var gui : GUIController

func initialize(card : Card, _gui : GUIController):
	card_display = card.create_card_display()
	card_display.gui_embedded = true
	gui = _gui

func from_template(template : CardTemplate, dragging := false):
	card_display = Templates.card_prefab.instantiate()
	card_display.from_template(template)

#either initialize or from_template need to be called on 
#this object before adding it to the scene tree
func _ready():
	if gui != null:
		gui_card_input_event.connect(gui.game_manager.input_controller.card_gui_input_event)
	for connected in card_display.card_input_event.get_connections():
		card_display.card_input_event.disconnect(connected)
	add_child(card_display)
	card_display.position = custom_minimum_size / 2
	gui_input.connect(func (event):
		gui_card_input_event.emit(self, event)
	)

func _get_drag_data(at_position):
	drag_started.emit(self)
	return self
	
func _can_drop_data(at_position, data):
	if data is CardGUIDisplay:
		return true
	return false

func _drop_data(at_position, data):
	data_drop_received.emit(self, data)
