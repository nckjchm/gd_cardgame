class_name ChoicePopupMenu extends PanelContainer

var choices : Dictionary
var gui : GUIController
var game_manager : GameManager
@onready var menu_container : VBoxContainer = $MenuContainer

func initialize(_choices : Dictionary, _gui : GUIController, _game_manager : GameManager):
	choices = _choices
	gui = _gui
	game_manager = _game_manager

func _ready():
	for choice_key in choices:
		var choice : Dictionary = choices[choice_key]
		var btn_choice := Button.new()
		btn_choice.text = choice.label
		btn_choice.pressed.connect(func():
			close()
			choice.on_click.call()
		)
		menu_container.add_child(btn_choice)

func close():
	gui.close_choice_popup_menu()
