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
@onready var btn_deck_editor : Button = $MidPanel/MainMenuVB/DeckEditor
@onready var ip_field : LineEdit = $MidPanel/IPMenu/AdressField
var lobby_scene = preload("res://lobby.tscn")
var deck_editor_scene = preload("res://deck_editor.tscn")
var deck_editor : DeckEditor = null

func _ready():
	setup()
	btn_host_game.pressed.connect(func():
		lobby_manager.build_player_info()
		lobby_manager.create_game()
	)
	btn_join_game.pressed.connect(func():
		open_ip_menu()
	)
	btn_ip_connect.pressed.connect(func():
		lobby_manager.build_player_info()
		lobby_manager.join_game(ip_field.text)
		btn_ip_connect.disabled = true
	)
	btn_ip_exit.pressed.connect(func():
		exit_ip_menu()
	)
	btn_deck_editor.pressed.connect(func():
		open_deck_editor()
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

func setup():
	var decks_dir = "user://decks/"
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(decks_dir)
	var deck_files = DirAccess.get_files_at(decks_dir)
	for deck_file_path in deck_files:
		if deck_file_path.ends_with(".tcgdeck"):
			var deck_file = FileAccess.open("%s%s" % [decks_dir, deck_file_path], FileAccess.READ)
			var deck_data = JSON.parse_string(deck_file.get_line())
			Templates.save_deck_template(DeckTemplate.from_serialized(deck_data))

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
	var lobby_menu = lobby_scene.instantiate()
	mid_panel.add_child(lobby_menu)
	lobby_manager.lobby_menu = lobby_menu

func open_deck_editor():
	mid_panel.hide()
	deck_editor = deck_editor_scene.instantiate()
	add_child(deck_editor)

func close_deck_editor():
	if deck_editor != null:
		deck_editor.queue_free()
		mid_panel.show()
