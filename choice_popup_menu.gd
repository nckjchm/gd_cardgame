class_name ChoicePopupMenu extends PanelContainer

var choices : Dictionary
var gui : GUIController
var game_manager : GameManager
@onready var menu_container : VBoxContainer = $MenuContainer

func initialize(choices : Dictionary, gui : GUIController, gm : GameManager):
	self.choices = choices
	self.gui = gui
	self.game_manager = gm

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
