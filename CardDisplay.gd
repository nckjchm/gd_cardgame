class_name CardDisplay extends CanvasGroup

signal card_input_event(card_display : CardDisplay, viewport, event, shape_idx)

const card_color_presets = [ Color.RED, Color.BLUE, Color.FOREST_GREEN, Color.YELLOW, Color.BLACK, Color.WHITE ]

var card : Card = null
@onready var card_area : Area2D = $CardArea
@onready var input_controller : InputController = $"/root/Main/Game/InputController"
@onready var name_text_mesh : MeshInstance2D = $NameTextMesh
@onready var cost_text_mesh : MeshInstance2D = $CostTextMesh
@onready var attribute_text_mesh : MeshInstance2D = $AttributeTextMesh
@onready var card_text_mesh : MeshInstance2D = $CardTextMesh
@onready var attack_text_mesh : MeshInstance2D = $AttackTextMesh
@onready var speed_text_mesh : MeshInstance2D = $SpeedTextMesh
@onready var health_text_mesh : MeshInstance2D = $HealthTextMesh
@onready var defense_text_mesh : MeshInstance2D = $DefenseTextMesh
@onready var background : Polygon2D = $CardArea/Background
var meshes : Array[MeshInstance2D]
var gui_embedded := false

func initialize(_card : Card):
	card = _card

func _ready():
	card.health_updated.connect(_on_health_updated)
	card.defense_updated.connect(_on_defense_updated)
	card.attack_updated.connect(_on_attack_updated)
	card.speed_updated.connect(_on_speed_updated)
	card.tap_state_updated.connect(_on_tap_state_updated)
	card.controller_updated.connect(_on_controller_updated)
	card.name_updated.connect(_on_name_updated)
	card.position_updated.connect(_on_position_updated)
	card.color_updated.connect(_on_color_updated)
	card.card_status_updated.connect(_on_card_status_updated)
	card_input_event.connect(input_controller.card_input_event)
	init_meshes()
	adjust_presentation()

func adjust_rotation():
	if gui_embedded or card.card_position == Card.CardPosition.Hand:
		rotation = 0
		return
	var tap_deg : float = (30 * card.tap_status)
	rotation = deg_to_rad(card.controller.rotation + tap_deg)

func adjust_color(front_visible := true):
	background.color = card_color_presets[card.card_color] if front_visible else Color.SADDLE_BROWN
	var text_color = Color.WHITE if not card.card_color in [Card.CardColor.Yellow, Card.CardColor.White] else Color.BLACK
	for mesh in meshes:
		mesh.modulate = text_color

func adjust_presentation():
	var front_visible := card.card_status != Card.CardStatus.Hidden or card.card_position == Card.CardPosition.Hand
	set_content_visibility(front_visible)
	adjust_color(front_visible)

func set_content_visibility(front_visible := true):
	for mesh in meshes:
		mesh.visible = front_visible

func init_meshes():
	meshes = [name_text_mesh, cost_text_mesh, attribute_text_mesh, card_text_mesh, attack_text_mesh, speed_text_mesh, health_text_mesh, defense_text_mesh]
	for mesh_obj in meshes:
		var mesh := TextMesh.new()
		mesh_obj.mesh = mesh
		mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		mesh.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		mesh.font_size = 50
		mesh.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_text_mesh.mesh.text = card.card_name
	name_text_mesh.mesh.font_size = 76
	name_text_mesh.mesh.width = 620
	attack_text_mesh.mesh.text = str(card.attack)
	speed_text_mesh.mesh.text = str(card.speed)
	health_text_mesh.mesh.text = str(card.health)
	defense_text_mesh.mesh.text = str(card.defense)
	var cost_text := ""
	for element in card.cost.elements:
		cost_text += element.get_text()
	cost_text_mesh.mesh.text = cost_text
	cost_text_mesh.mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_text_mesh.mesh.text_direction = TextServer.Direction.DIRECTION_LTR
	var aspects_text = ""
	for aspect in card.card_aspects:
		aspects_text = ", ".join([aspects_text, Card.get_aspect_name(aspect)])
	attribute_text_mesh.mesh.text = "[%s]" % aspects_text.substr(2)
	var card_text = ""
	if not card.flavor_text.is_empty():
		card_text = card.flavor_text
	for effect in card.effects:
		card_text += effect.long_text + "\n"
	card_text_mesh.mesh.text = card_text

func _on_health_updated(_card):
	health_text_mesh.mesh.text = str(card.health)

func _on_defense_updated(_card):
	defense_text_mesh.mesh.text = str(card.defense)

func _on_attack_updated(_card):
	attack_text_mesh.mesh.text = str(card.attack)

func _on_speed_updated(_card):
	speed_text_mesh.mesh.text = str(card.speed)

func _on_name_updated(_card):
	name_text_mesh.mesh.text = str(card.name)

func _on_tap_state_updated(_card):
	adjust_rotation()

func _on_controller_updated(_card):
	adjust_rotation()

func _on_position_updated(_card):
	adjust_rotation()

func _on_color_updated(_card):
	adjust_color(card.card_status != Card.CardStatus.Hidden or card.card_position == Card.CardPosition.Hand)

func _on_card_status_updated(_card):
	adjust_presentation()

func _on_card_area_input_event(viewport, event, shape_idx):
	card_input_event.emit(self, viewport, event, shape_idx)
