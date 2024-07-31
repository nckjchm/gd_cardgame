class_name Card

enum CardStatus { Alive, Dead, Limbo, Banished, Hidden }
enum CardPosition { Deck, Hand, Field, Graveyard, Limbo, Banishment, Unknown}
enum CardColor { Red, Blue, Green, Yellow, Black, White }
enum CardType { Creature, Structure, Spell, Land }
enum CardOrigin { MainDeck, ResourceDeck, SpecialDeck, Token }
enum CardAspect { Land, Humanoid, Animalia, Necro, Pyro, Aquatic, Liquid, Aerial, Astral, Sinister, Herbal, Magicae }

signal card_died(card : Card)
signal health_updated(card : Card)
signal defense_updated(card : Card)
signal attack_updated(card : Card)
signal speed_updated(card : Card)
signal tap_state_updated(card : Card)
signal controller_updated(card : Card)
signal name_updated(card : Card)
signal position_updated(card : Card)
signal color_updated(card : Card)
signal card_status_updated(card : Card)

#base data
var template : CardTemplate
var id : int
var cell : Cell = null
var card_owner : Player
var controller : Player:
	get : return controller
	set(value):
		controller = value
		controller_updated.emit(self)
#card stats
var health : int :
	get: return health
	set(value):
		health = value
		health_updated.emit(self)
var defense : int:
	get: return defense
	set(value):
		defense = value
		defense_updated.emit(self)
var attack : int:
	get: return attack
	set(value):
		attack = value
		attack_updated.emit(self)
var speed : int:
	get: return speed
	set(value):
		speed = value
		speed_updated.emit(self)
#card info
var card_name : String:
	get: return card_name
	set(value):
		card_name = value
		name_updated.emit(self)
var tap_status : int:
	get: return tap_status
	set(value):
		tap_status = value
		tap_state_updated.emit(self)
var card_status : CardStatus = CardStatus.Hidden:
	get: return card_status
	set(value):
		card_status = value
		card_status_updated.emit(self)
var card_position : CardPosition = CardPosition.Deck :
	get: return card_position
	set(value):
		card_position = value
		position_updated.emit(self)
var card_type : CardType
var card_color : CardColor:
	get: return card_color
	set(value):
		card_color = value
		color_updated.emit(self)
var flavor_text : String
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
var on_field_display : CardDisplay
#technical

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

func _init(template : CardTemplate, id : int, card_owner : Player, card_origin : CardOrigin, effect_id_start : int):
	self.template = template
	self.id = id
	self.card_owner = card_owner
	self.card_origin = card_origin
	var effect_id := effect_id_start
	for effect_template in template.effects:
		effects.append(CardEffect.new(effect_template, self, effect_id))
		effect_id += 1
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
	card_aspects = template.card_aspects
	play_condition = template.play_condition
	play_cell_scope = func(gm : GameManager): return template.play_cell_scope.call(self, gm)
	cost = template.cost
	can_coexist = template.can_coexist
	flavor_text = template.flavor_text
	refresh_stats()
	card_color = template.card_color
	on_field_display = create_card_display()

func create_card_display():
	var card_display : CardDisplay = Templates.card_prefab.instantiate()
	card_display.initialize(self)
	return card_display

func refresh_stats():
	health = template.health
	defense = template.defense
	attack = template.attack
	speed = template.speed
	tap_status = 0

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

static func get_aspect_name(aspect : CardAspect):
	return CardAspect.keys()[aspect]
