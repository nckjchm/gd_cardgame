class_name MainMenu extends Control

@onready var name_field : LineEdit = $MidPanel/MainMenuVB/NameField
@onready var lobby_manager : LobbyManager = $LobbyManager
@onready var player_manager : PlayerManager = $PlayerManager
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
		lobby_manager.player_info = {name = player_manager.local_player.name}
		lobby_manager.create_game()
	)
	btn_join_game.pressed.connect(func():
		open_ip_menu()
	)
	btn_ip_connect.pressed.connect(func():
		lobby_manager.player_info = {name = player_manager.local_player.name}
		lobby_manager.join_game(ip_field.text)
		btn_ip_connect.disabled = true
	)
	btn_ip_exit.pressed.connect(func():
		exit_ip_menu()
	)
	lobby_manager.player_connected.connect(func(peer_id, player_info):
		print("connected - peer id: %d local id: %d" % [peer_id, multiplayer.get_unique_id()])
		if peer_id == multiplayer.get_unique_id():
			print("opening lobby on: %d" %peer_id)
			open_lobby()
	)
	lobby_manager.connection_refused.connect(func():
		exit_ip_menu()
	)
	name_field.text = player_manager.local_player.name
	name_field.text_changed.connect(func(): player_manager.player.name = name_field.text)

func open_ip_menu():
	main_menu_vbox.visible = false
	ip_menu.visible = true

func exit_ip_menu():
	ip_menu.visible = false
	main_menu_vbox.visible = true

func open_lobby():
	ip_menu.visible = false
	main_menu_vbox.visible = false
	mid_panel.add_child(lobby_scene.instantiate())
