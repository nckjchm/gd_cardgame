class_name Cell extends Area2D

signal cell_input_event(cell, viewport, event, shape_idx)
@onready var input_controller : InputController = $"../../../../../InputController"
@onready var field : Field = $/root/Main/GameViewContainer/FieldVPC/FieldVP/Field
var rng = RandomNumberGenerator.new()

enum CellType { Inactive, Stack, Field }
enum StackType { MainDeck, ResourceDeck, SpecialDeck, Graveyard, Limbo, Banishment, None }

var cards : Array[Card] = []
var diameter : int
var cell_view_hex : Polygon2D
var cell_click_hex : CollisionPolygon2D
var cell_center
var grid_row : int
var grid_column : int
var preset_player : int
var cell_type : CellType
var stack_type : StackType
var short_name : String
var full_name : String

func insert_card(card : Card, pos : int = len(cards)):
	add_child(card.on_field_display)
	cards.insert(pos, card)
	refresh_cards()
	
func remove_card(card : Card):
	cards.erase(card)
	remove_child(card.on_field_display)
	refresh_cards()
	
func refresh_cards():
	for card_index in len(cards):
		var card = cards[card_index]
		card.on_field_display.z_index = card_index + 1
		card.on_field_display.position = position
		card.index_in_stack = card_index

func _init(pos : Vector2, diam : int, row : int, column : int, c_type := CellType.Inactive, s_type := StackType.None, player = -1):
	diameter = diam 
	position = pos
	grid_row = row
	grid_column = column
	cell_type = c_type
	stack_type = s_type
	preset_player = player
	cell_view_hex = Polygon2D.new()
	add_child(cell_view_hex)
	cell_click_hex = CollisionPolygon2D.new()
	add_child(cell_click_hex)
	var hex_points = Array()
	hex_points.resize(6)
	for i in hex_points.size():
		var angle_deg = 60 * i - 30
		var angle_rad = PI / 180 * angle_deg
		hex_points[i] = Vector2(position.x + diameter * cos(angle_rad), position.y + diameter * sin(angle_rad))
	cell_view_hex.polygon = hex_points
	cell_click_hex.polygon = hex_points
	set_according_color()
	short_name = "Cell[%d|%d]" % [grid_row, grid_column]
	full_name = "Cell [%d|%d] - %s" % [grid_row, grid_column, cell_type]
	
func set_according_color():
	match cell_type:
		Cell.CellType.Field:
			change_color(Color.LAWN_GREEN)
		Cell.CellType.Inactive:
			change_color(Color.SLATE_GRAY)
			hide()
		Cell.CellType.Stack:
			change_color(Color.MEDIUM_PURPLE)

func player_activation():
	print("Cell clicked - row: %d, colum: %d" % [grid_row, grid_column])
		
func change_color(color: Color):
	cell_view_hex.modulate = color

func random_color():
	return Color.hex(rng.randi_range(0, 0xffffff) + 0xff000000)

func _ready():
	cell_input_event.connect(input_controller.cell_input_event)

func _input_event(viewport, event, shape_idx):
	cell_input_event.emit(self, viewport, event, shape_idx)
