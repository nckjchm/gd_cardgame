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
var controller : Player
#card stats
var health : int
var defense : int
var attack : int
var speed : int
#card info
var card_name : String
var tap_status : int
var card_status : CardStatus = CardStatus.Hidden
var card_position : CardPosition = CardPosition.Deck
var card_type : CardType
var card_color : CardColor
var card_aspects : Array[CardAspect]
var card_origin : CardOrigin
var microstates : Dictionary = {}
var effects : Array[CardEffect] = []
var cost : Game.ResourceList
var has_attacked := false
var needs_recovery := false
var has_moved := false
var index_in_stack := 0
var play_condition : Callable
var play_cell_scope : Callable
#technical
@onready var card_area : Area2D = $CardArea
@onready var input_controller : InputController = $/root/Main/InputController
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

func initialize(template : CardTemplate, id : int, card_owner : Player, card_origin : CardOrigin, effect_id_start : int):
	self.template = template
	self.id = id
	self.card_owner = card_owner
	self.card_origin = card_origin
	card_name = template.name
	card_type = template.type
	play_condition = template.play_condition
	play_cell_scope = func(gm : GameManager): return template.play_cell_scope.call(self, gm)
	cost = template.cost
	var effect_id := effect_id_start
	for effect_template in template.effects:
		effects.append(CardEffect.new(effect_template, self, effect_id))
		effect_id += 1
	refresh_stats()

func refresh_stats():
	health = template.health
	defense = template.defense
	attack = template.attack
	speed = template.speed
	tap_status = 0

func check_attack_viability(gm : GameManager):
	if tap_status == 0 and not has_attacked and card_position == CardPosition.Field and card_type == CardType.Creature and gm.game.current_turn.current_phase == Game.TurnPhase.Battle:
		#Needs additional check for whether there are any viable targets
		return true
	return false

func check_movement_viability(gm : GameManager):
	return tap_status == 0 and not has_moved and card_type == CardType.Creature and card_position == CardPosition.Field and gm.game.current_turn.current_phase in [Game.TurnPhase.Main1, Game.TurnPhase.Main2]

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
	print(to_string() + " died")
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
	
func set_color(card_color : CardColor):
	self.card_color = card_color
	var black_text := false
	background.color = card_color_presets[card_color]
	if card_color in [CardColor.Yellow, CardColor.White]:
		black_text = true
	var text_color = Color.WHITE
	if black_text:
		text_color = Color.BLACK
	for mesh in meshes:
		mesh.modulate = text_color

# Called when the node enters the scene tree for the first time.
func _ready():
	card_input_event.connect(input_controller.card_input_event)
	meshes = [name_text_mesh, cost_text_mesh, attribute_text_mesh, card_text_mesh, attack_text_mesh, speed_text_mesh, health_text_mesh, defense_text_mesh]
	for mesh_obj in meshes:
		var mesh := TextMesh.new()
		mesh_obj.mesh = mesh
		mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		mesh.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		mesh.font_size = 50
		mesh.autowrap_mode = TextServer.AUTOWRAP_WORD
	init_meshes()
	set_color(template.card_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_card_area_input_event(viewport, event, shape_idx):
	card_input_event.emit(self, viewport, event, shape_idx)

