class_name MainMenu extends Control

@onready var name_field : LineEdit = $MidPanel/MainMenuVB/NameField
@onready var lobby_manager : LobbyManager = $LobbyManager
@onready var main_menu_vbox : VBoxContainer = $MidPanel/MainMenuVB
@onready var ip_menu : VBoxContainer = $MidPanel/IPMenu
@onready var mid_panel : PanelContainer = $MidPanel
@onready var btn_join_game : Button = $MidPanel/MainMenuVB/JoinGame
@onready var btn_host_game : Button = $MidPanel/MainMenuVB/HostGame
@onready var btn_ip_connect : Button = $MidPanel/IPMenu/JoinGame
@onready var btn_ip_exit : Button = $MidPanel/IPMenu/Exit
@onready var ip_field : LineEdit = $MidPanel/IPMenu/AdressField
var lobby_scene = preload("res://lobby.tscn")

func _ready():
	btn_host_game.pressed.connect(func():
		build_player_info()
		lobby_manager.create_game()
	)
	btn_join_game.pressed.connect(func():
		open_ip_menu()
	)
	btn_ip_connect.pressed.connect(func():
		build_player_info()
		lobby_manager.join_game(ip_field.text)
		btn_ip_connect.disabled = true
	)
	btn_ip_exit.pressed.connect(func():
		exit_ip_menu()
	)
	lobby_manager.game_joined.connect(func(peer_id, _local_player_info):
		if peer_id == multiplayer.get_unique_id():
			open_lobby()
	)
	lobby_manager.connection_refused.connect(func():
		exit_ip_menu()
	)
	name_field.text = lobby_manager.local_player_info.name
	name_field.text_changed.connect(func(new_text): lobby_manager.local_player_info.name = new_text)

func build_player_info():
	var deck_name = lobby_manager.local_player_info.deck_template
	lobby_manager.local_player_info = {
		name = lobby_manager.local_player_info.name,
		deck_template = deck_name,
		deck = {
			name = deck_name,
			maindeck = Templates.deck_templates[deck_name].main_deck_keys,
			resourcedeck = Templates.deck_templates[deck_name].resource_deck_keys,
			specialdeck = Templates.deck_templates[deck_name].special_deck_keys
		},
		seat = -1
	}

func open_ip_menu():
	main_menu_vbox.visible = false
	ip_menu.visible = true

func exit_ip_menu():
	ip_menu.visible = false
	main_menu_vbox.visible = true
	lobby_manager.remove_multiplayer_peer()
	btn_ip_connect.disabled = false

func open_lobby():
	ip_menu.visible = false
	main_menu_vbox.visible = false
	mid_panel.add_child(lobby_scene.instantiate())
