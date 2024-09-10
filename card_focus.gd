class_name CardFocus extends Control

signal card_focus_input_event(card_focus : Control, event : Event)

@onready var card_gui_container = $CardGUIContainer
@onready var lbl_card_name = $CardName
@onready var lbl_card_type = $CardType
@onready var lbl_card_aspects = $CardAspects
@onready var lbl_card_health = $CardHealth
@onready var lbl_card_defense = $CardDefense
@onready var lbl_card_attack = $CardAttack
@onready var lbl_card_speed = $CardSpeed
@onready var lbl_card_text = $CardText
var card_gui_display : CardGUIDisplay
var gui : GUIController

func initialize(card : Card, _gui):
	gui = _gui
	card_gui_display = Templates.card_gui_display_prefab.instantiate()
	card_gui_display.initialize(card, gui)
	card_focus_input_event.connect(gui.game_manager.input_controller.menu_input_event)

func _ready():
	card_gui_container.add_child(card_gui_display)
