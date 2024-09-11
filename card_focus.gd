class_name CardFocus extends Control

signal card_focus_input_event(card_focus : Control, event : Event)

@onready var card_gui_container = $CardGUIContainer
@onready var lbl_card_name : Label = $CardName
@onready var lbl_card_cost : Label = $CardCost
@onready var lbl_card_type : Label = $CardType
@onready var lbl_card_aspects : Label = $CardAspects
@onready var lbl_card_health : Label = $CardHealth
@onready var lbl_card_defense : Label = $CardDefense
@onready var lbl_card_attack : Label = $CardAttack
@onready var lbl_card_speed : Label = $CardSpeed
@onready var lbl_card_tap_status : Label = $CardTapStatus
@onready var lbl_card_text : Label = $CardText
@onready var lbl_card_controller : Label = $CardController
@onready var lbl_card_position : Label = $CardPosition
@onready var lbl_card_cell : Label = $CardCell
@onready var lbl_card_status : Label = $CardStatus
var card_gui_display : CardGUIDisplay
var gui : GUIController
var base_card : Card
var current_card_id := -1

func initialize(card : Card, _gui : GUIController):
	gui = _gui
	base_card = card

func _ready():
	focus_card(base_card)
	card_focus_input_event.connect(gui.game_manager.input_controller.menu_input_event)

func clear():
	if card_gui_display != null:
		card_gui_display.queue_free()
	for connection_info in get_incoming_connections():
		connection_info["signal"].disconnect(connection_info.callable)
	set_hidden_labels()

func set_hidden_labels():
	lbl_card_name.text = "Hidden Card"
	lbl_card_cost.hide()
	lbl_card_type.hide()
	lbl_card_aspects.hide()
	lbl_card_health.hide()
	lbl_card_defense.hide()
	lbl_card_attack.hide()
	lbl_card_speed.hide()
	lbl_card_text.hide()
	lbl_card_position.text = Card.get_position_name(base_card.card_position)
	lbl_card_cell.text = base_card.cell.full_name if base_card.card_position != Card.CardPosition.Hand else "Hand"
	lbl_card_status.text = Card.get_status_name(base_card.card_status)
	lbl_card_tap_status.text = "Tap Status: %d" % base_card.tap_status

func set_shown_labels():
	lbl_card_name.text = base_card.card_name
	var card_cost_text = card_gui_display.card_display.get_cost_text()
	if card_cost_text.is_empty():
		lbl_card_cost.hide()
	else:
		lbl_card_cost.show()
		lbl_card_cost.text = card_cost_text
	lbl_card_controller.text = base_card.controller.name
	lbl_card_type.show()
	lbl_card_type.text = Card.get_type_name(base_card.card_type)
	if base_card.card_type == Card.CardType.Land:
		lbl_card_aspects.hide()
	else:
		lbl_card_aspects.show()
		lbl_card_aspects.text = card_gui_display.card_display.get_aspects_text()
	lbl_card_health.show()
	lbl_card_health.text = "Health: %d" % base_card.health
	lbl_card_defense.show()
	lbl_card_defense.text = "Defense: %d" % base_card.defense
	lbl_card_attack.show()
	lbl_card_attack.text = "Attack: %d" % base_card.attack
	lbl_card_speed.show()
	lbl_card_speed.text = "Speed: %d" % base_card.speed
	lbl_card_text.show()
	lbl_card_text.text = card_gui_display.card_display.get_card_text()

func focus_card(card : Card):
	if card.id == current_card_id:
		return
	base_card = card
	current_card_id = card.id
	clear()
	card.health_updated.connect(_on_health_updated)
	card.defense_updated.connect(_on_defense_updated)
	card.attack_updated.connect(_on_attack_updated)
	card.speed_updated.connect(_on_speed_updated)
	card.tap_state_updated.connect(_on_tap_state_updated)
	card.controller_updated.connect(_on_controller_updated)
	card.name_updated.connect(_on_name_updated)
	card.position_updated.connect(_on_position_updated)
	card.card_status_updated.connect(_on_card_status_updated)
	card.cell_updated.connect(_on_cell_updated)
	base_card = card
	card_gui_display = Templates.card_gui_display_prefab.instantiate()
	card_gui_display.initialize(card, gui)
	card_gui_container.add_child(card_gui_display)
	if card.card_status != Card.CardStatus.Hidden or (card.controller == gui.game_manager.local_player and card.card_position == Card.CardPosition.Hand):
		set_shown_labels()
	queue_redraw()

func _on_health_updated(card : Card):
	lbl_card_health.text = "Health: %d" % card.health

func _on_defense_updated(card : Card):
	lbl_card_defense.text = "Defense: %d" % card.defense

func _on_attack_updated(card : Card):
	lbl_card_attack.text = "Attack: %d" % card.attack

func _on_speed_updated(card : Card):
	lbl_card_speed.text = "Speed: %d" % card.speed

func _on_tap_state_updated(card : Card):
	print("tap status updated: %d" % card.tap_status)
	lbl_card_tap_status.text = "Tap Status: %d" % card.tap_status

func _on_controller_updated(card : Card):
	lbl_card_controller.text = card.controller.name
	if card.controller != gui.game_manager.local_player and card.card_position == Card.CardPosition.Hand:
		set_hidden_labels()

func _on_name_updated(card : Card):
	lbl_card_name.text = card.card_name

func _on_position_updated(card : Card):
	lbl_card_position.text = Card.get_position_name(card.card_position)

func _on_card_status_updated(card : Card):
	lbl_card_status.text = Card.get_status_name(card.card_status)
	if card.card_status == Card.CardStatus.Hidden and not (card.controller == gui.game_manager.local_player and card.card_position == Card.CardPosition.Hand):
		set_hidden_labels()

func _on_cell_updated(card : Card):
	print("cell updated")
	lbl_card_cell.text = card.cell.full_name
