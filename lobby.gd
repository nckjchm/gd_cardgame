class_name Lobby extends Control

@onready var players_container : GridContainer = $PlayersContainer
@onready var btn_start : Button = $StartGame
@onready var btn_exit : Button = $Exit
@onready var lobby_manager : LobbyManager = $"../../LobbyManager"
var game_scene = preload("res://game.tscn")
var players : Array[Player]

func _ready():
	btn_start.pressed.connect(func():
		lobby_manager.load_game.rpc("res://game.tscn")
	)
	btn_exit.pressed.connect(func():
		lobby_manager.remove_multiplayer_peer()
		close()
	)
	btn_start.disabled = not multiplayer.is_server()

func add_player(player : Player):
	var player_name_label = Label.new()
	player_name_label.text = player.name
	

func close():
	var main_menu : VBoxContainer = $"../MainMenuVB"
	main_menu.visible = true
	self.queue_free()
