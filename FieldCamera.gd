class_name FieldCamera extends Camera2D

@export var min_zoom := 0.2
@export var max_zoom := 2.0
@onready var field : Field = $"../Field"

func _ready():
	zoom = Vector2(0.5, 0.5)
	position = field.middle

func adjust_zoom(factor : float):
	zoom *= factor
	zoom = Vector2(max_zoom,max_zoom) if zoom.x > max_zoom else Vector2(min_zoom,min_zoom) if zoom.x < min_zoom else zoom

func move_camera(movement):
	movement /= zoom
	movement = movement.rotated(rotation)
	position -= movement
	var bounding_width = field.middle.x * 2
	var bounding_height = field.middle.y * 2
	position.x = 0.0 if position.x < 0.0 else bounding_width if position.x > bounding_width else position.x
	position.y = 0.0 if position.y < 0.0 else bounding_height if position.y > bounding_height else position.y

func adjust_rotation(rotation_deg : float):
	rotation = deg_to_rad(rotation_deg)
