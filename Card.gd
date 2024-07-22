class_name Card extends CanvasGroup

enum CardStatus { Alive, Dead, Limbo, Banished, Hidden }
enum CardPosition { Deck, Hand, Field, Graveyard, Limbo, Banishment, Unknown}
enum CardColor { Red, Blue, Green, Yellow, Black, White }
enum CardType { Creature, Structure, Spell, Land }
enum CardOrigin { MainDeck, ResourceDeck, SpecialDeck, Token }
enum CardAspect { Humanoid, Feral, Necro, Pyro, Aquatic, Liquid, Aerial, Astral, Infernal, Herbal, Magicae }

signal card_input_event(card : Card, viewport, event, shape_idx)
signal card_died(card : Card)

const card_color_presets = [ Color.RED, Color.BLUE, Color.FOREST_GREEN, Color.YELLOW, Color.BLACK, Color.WHITE ]

#base data
var template : CardTemplate
var id : int
var cell : Cell = null
var card_owner : Player
var controller : Player:
	get : return controller
	set(value):
		controller = value
		adjust_rotation()
#card stats
var health : int :
	get: return health
	set(value):
		health = value
		health_text_mesh.mesh.text = str(health)
var defense : int:
	get: return defense
	set(value):
		defense = value
		defense_text_mesh.mesh.text = str(defense)
var attack : int:
	get: return attack
	set(value):
		attack = value
		attack_text_mesh.mesh.text = str(attack)
var speed : int:
	get: return speed
	set(value):
		speed = value
		speed_text_mesh.mesh.text = str(speed)
#card info
var card_name : String:
	get: return card_name
	set(value):
		card_name = value
		name_text_mesh.mesh.text = card_name
var tap_status : int:
	get: return tap_status
	set(value):
		tap_status = value
		adjust_rotation()
var card_status : CardStatus = CardStatus.Hidden:
	get: return card_status
	set(value):
		card_status = value
		adjust_presentation()
var card_position : CardPosition = CardPosition.Deck :
	get: return card_position
	set(value):
		card_position = value
		adjust_rotation()
var card_type : CardType
var card_color : CardColor:
	get: return card_color
	set(value):
		card_color = value
		adjust_color()
		var text_color = Color.WHITE if not card_color in [CardColor.Yellow, CardColor.White] else Color.BLACK
		for mesh in meshes:
			mesh.modulate = text_color
var card_aspects : Array[CardAspect]
var card_origin : CardOrigin
var microstates : Dictionary = {}
var effects : Array[CardEffect] = []
var cost : ResourceList
var has_attacked := false
var needs_recovery := false
var has_moved := false
var index_in_stack := 0
var play_condition : Callable
var play_cell_scope : Callable
var can_coexist : bool
#technical
@onready var card_area : Area2D = $CardArea
@onready var input_controller : InputController = $"../../../../../../InputController"
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
var step_scope : Callable = func(gm : GameManager):
	var cells : Array[Cell] = gm.field.get_cells_in_distance([cell], 1)
	cells = cells.filter(func(cell : Cell):
		for check_card in cell.cards:
			if not check_card.can_coexist:
				return false
		return true
	)
	return cells

var attack_scope := func(gm : GameManager):
	var neighboring_cells : Array[Cell] = gm.field.get_neighbor_cells(cell)
	var cards : Array[Card] = gm.game.all_cards.filter(
		func(check_target : Card):
			return controller != check_target.controller and check_target.cell in neighboring_cells and check_target.card_status == Card.CardStatus.Alive and check_target.health > 0
	)
	return cards

func initialize(template : CardTemplate, id : int, card_owner : Player, card_origin : CardOrigin, effect_id_start : int):
	self.template = template
	self.id = id
	self.card_owner = card_owner
	self.card_origin = card_origin
	var effect_id := effect_id_start
	for effect_template in template.effects:
		effects.append(CardEffect.new(effect_template, self, effect_id))
		effect_id += 1

func refresh_stats():
	health = template.health
	defense = template.defense
	attack = template.attack
	speed = template.speed
	tap_status = 0

func adjust_rotation():
	if card_position == CardPosition.Hand:
		rotation = 0
		return
	var tap_deg : float = (30 * tap_status)
	rotation = deg_to_rad(controller.rotation + tap_deg)

func adjust_presentation():
	var front_visible := card_status != CardStatus.Hidden or card_position == CardPosition.Hand
	set_content_visibility(front_visible)
	adjust_color(front_visible)

func adjust_color(front_visible := true):
	background.color = card_color_presets[card_color] if front_visible else Color.SADDLE_BROWN

func set_content_visibility(front_visible := true):
	for mesh in meshes:
		mesh.visible = front_visible

func check_attack_viability(gm : GameManager):
	if tap_status == 0 and not has_attacked and card_position == CardPosition.Field and card_type == CardType.Creature and gm.game.current_turn.current_phase == Turn.TurnPhase.Battle:
		#Needs additional check for whether there are any viable targets
		var targets : Array[Card] = attack_scope.call(gm)
		return len(targets) > 0
	return false

func check_movement_viability(gm : GameManager):
	return tap_status == 0 and not has_moved and card_type == CardType.Creature and card_position == CardPosition.Field and gm.game.current_turn.current_phase in [Turn.TurnPhase.Main1, Turn.TurnPhase.Main2]

func check_play_viability(gm : GameManager):
	if not card_position == CardPosition.Hand:
		return false
	if not card_owner.resources.check_coverage(cost):
		return false
	if card_type == CardType.Creature and gm.game.current_turn.creature_called:
		return false
	return play_condition.call(self, gm)

func check_recovery_viability():
	return card_position == CardPosition.Field and (defense < template.defense or tap_status > 0)

func player_enters_round():
	has_attacked = false
	needs_recovery = false
	has_moved = false

func die():
	print("Card with id %d died" % id)
	card_status = CardStatus.Dead

func init_meshes():
	name_text_mesh.mesh.text = card_name
	name_text_mesh.mesh.font_size = 76
	name_text_mesh.mesh.width = 620
	attack_text_mesh.mesh.text = str(attack)
	speed_text_mesh.mesh.text = str(speed)
	health_text_mesh.mesh.text = str(health)
	defense_text_mesh.mesh.text = str(defense)
	cost_text_mesh.mesh.text = "Cost"
	attribute_text_mesh.mesh.text = "[Attribute]"
	card_text_mesh.mesh.text = "Card Text"
	

# Called when the node enters the scene tree for the first time.
func _ready():
	card_input_event.connect(input_controller.card_input_event)
	controller = card_owner
	match card_origin:
		CardOrigin.MainDeck:
			cell = card_owner.maindeck_cell
		CardOrigin.ResourceDeck:
			cell = card_owner.resourcedeck_cell
		CardOrigin.SpecialDeck:
			cell = card_owner.specialdeck_cell
	card_name = template.name
	card_type = template.type
	play_condition = template.play_condition
	play_cell_scope = func(gm : GameManager): return template.play_cell_scope.call(self, gm)
	cost = template.cost
	can_coexist = template.can_coexist
	meshes = [name_text_mesh, cost_text_mesh, attribute_text_mesh, card_text_mesh, attack_text_mesh, speed_text_mesh, health_text_mesh, defense_text_mesh]
	for mesh_obj in meshes:
		var mesh := TextMesh.new()
		mesh_obj.mesh = mesh
		mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		mesh.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		mesh.font_size = 50
		mesh.autowrap_mode = TextServer.AUTOWRAP_WORD
	refresh_stats()
	init_meshes()
	card_color = template.card_color
	adjust_presentation()

func _on_card_area_input_event(viewport, event, shape_idx):
	card_input_event.emit(self, viewport, event, shape_idx)

