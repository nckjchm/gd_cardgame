class_name CellMenu extends PanelContainer

var choices : Array = []
var buttons : Array = []
var gui : GUIController
var cell : Cell
@onready var menu_container : BoxContainer = $MenuContainer
@onready var lbl_cell_name : Label = $MenuContainer/NameLabel
@onready var btn_view_stack : Button = $MenuContainer/ViewStackButton
@onready var input_controller : InputController = $/root/Main/Game/InputController


func _ready():
	for choice in choices:
		var new_button = Button.new()
		new_button.text = choice.label
		new_button.pressed.connect(choice.on_click)
		new_button.mouse_filter = Control.MOUSE_FILTER_STOP
		new_button.custom_minimum_size = Vector2(83,26)
		menu_container.add_child(new_button)
		buttons.append(new_button)
	lbl_cell_name.text = cell.full_name
	btn_view_stack.pressed.connect(func():
		gui.open_card_list_menu(self.cell.cards, self.position)
		gui.close_cell_menu()
		input_controller.menu_clicked(self)
	)
	

func _process(delta):
	pass
