class_name CellMenu extends PanelContainer

var choices : Array = []
var buttons : Array = []
var gui : GUIController
var cell : Cell
@onready var menu_container : BoxContainer = $MenuContainer
@onready var lbl_cell_name : Label = $MenuContainer/NameLabel
@onready var btn_view_stack : Button = $MenuContainer/ViewStackButton

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

func _process(delta):
	pass
