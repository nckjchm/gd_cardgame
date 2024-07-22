class_name Lobby extends Control

@onready var players_container : GridContainer = $ConnectedPlayers
@onready var seats_container : GridContainer = $Seats
@onready var btn_start : Button = $StartGame
@onready var btn_exit : Button = $Exit
@onready var lobby_manager : LobbyManager = $"../../LobbyManager"
var players : Array[Player]
var player_name_labels : Array[Label]
var player_id_labels : Array[Label]

func _ready():
	btn_start.pressed.connect(func():
		lobby_manager.load_game.rpc("res://game.tscn")
	)
	btn_exit.pressed.connect(func():
		lobby_manager.remove_multiplayer_peer()
		close()
	)
	lobby_manager.player_info_updated.connect(func():
		redraw()
	)
	lobby_manager.server_disconnected.connect(close)
	btn_start.disabled = not multiplayer.is_server()
	redraw()

func redraw():
	empty()
	reparse_players()
	for player in players:
		add_connected_player_row(player)

func empty():
	for child in players_container.get_children():
		if child.get_index() > 1:
			players_container.remove_child(child)
	for child in seats_container.get_children():
		if child.get_index() > 1:
			seats_container.remove_child(child)

func reparse_players():
	players = []
	for key in lobby_manager.players:
		var player_info = lobby_manager.players[key]
		var new_player := Player.new(player_info.name)
		new_player.session_id = int(key)
		new_player.seat = -1
		var maindeck_keys : Array[String]
		var resourcedeck_keys : Array[String]
		var specialdeck_keys : Array[String]
		maindeck_keys.assign(player_info.deck.maindeck)
		resourcedeck_keys.assign(player_info.deck.resourcedeck)
		specialdeck_keys.assign(player_info.deck.specialdeck)
		var new_player_deck_template = DeckTemplate.new(player_info.deck.name, maindeck_keys, resourcedeck_keys, specialdeck_keys)
		new_player.deck = Deck.new(new_player_deck_template, player_info.deck.name)
		players.append(new_player)

func add_connected_player_row(player : Player):
	var id_label := Label.new()
	id_label.text = str(player.session_id)
	player_id_labels.append(id_label)
	players_container.add_child(id_label)
	var name_label := Label.new()
	name_label.text = player.name
	player_name_labels.append(name_label)
	players_container.add_child(name_label)


func close():
	var main_menu : VBoxContainer = $"../MainMenuVB"
	main_menu.visible = true
	self.queue_free()
