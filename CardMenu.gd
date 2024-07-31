class_name CardMenu extends PanelContainer

#Set this with a custom array of choice dictionaries
var choices : Array = []
#Is autmatically set based on the provided choices
var buttons : Array = []
var card : Card
var has_close_button := true
var gui : GUIController
@onready var menu_container : BoxContainer = $MenuContainer
@onready var lbl_name : Label = $MenuContainer/NameLabel

func _ready():
	lbl_name.text = card.card_name
	for choice in choices:
		var new_button = Button.new()
		new_button.text = choice.label
		new_button.pressed.connect(choice.on_click)
		new_button.mouse_filter = Control.MOUSE_FILTER_STOP
		new_button.custom_minimum_size = Vector2(83,26)
		menu_container.add_child(new_button)
		buttons.append(new_button)
		new_button.mouse_filter = Control.MOUSE_FILTER_PASS
	if has_close_button:
		var btn_exit := Button.new()
		btn_exit.text = "Close"
		btn_exit.pressed.connect(func(): gui.close_card_menu())
		menu_container.add_child(btn_exit)
		btn_exit.mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event):
	gui.game_manager.input_controller.menu_input_event(self, event, {})
