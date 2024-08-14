class_name DeckEditor extends Control

@onready var btn_exit : Button = $HLayout/LeftSideMenu/VLayout/Exit
@onready var maindeck_container : HFlowContainer = $HLayout/MidContent/MainDeck/VLayout/CardContainer
@onready var resourcedeck_container : HFlowContainer = $HLayout/MidContent/ResourceDeck/VBoxContainer/CardContainer
@onready var specialdeck_container : HFlowContainer = $HLayout/MidContent/SpecialDeck/VBoxContainer/CardContainer
@onready var lobby_manager : LobbyManager = $"../LobbyManager"
var deck_containers : Array[HFlowContainer]

func _ready():
	btn_exit.pressed.connect(func():
		get_parent().close_deck_editor()
	)
	deck_containers = [maindeck_container, resourcedeck_container, specialdeck_container]
	load_deck(lobby_manager.local_player_info.deck_template)

func load_deck(deck_name : String):
	clear_deck_display()
	var deck_template : DeckTemplate = Templates.deck_templates[deck_name]
	for maindeck_key in deck_template.main_deck_keys:
		var card_gui_display = Templates.card_gui_display_prefab.instantiate()
		card_gui_display.from_template(Templates.templates[maindeck_key])
		maindeck_container.add_child(card_gui_display)

func save_deck(deck_name : String):
	pass

func delete_deck(deck_name : String):
	pass

func clear_deck_display():
	for deck_container in deck_containers:
		for card_gui_display in deck_container.get_children():
			card_gui_display.queue_free()
