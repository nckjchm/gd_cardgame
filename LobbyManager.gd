class_name LobbyManager extends Node

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id)
signal game_joined(peer_id, player_info)
signal connection_refused
signal player_disconnected(peer_id)
signal player_info_updated
signal server_disconnected
signal choice_broadcast(choice)

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20
@onready var player_manager : PlayerManager = $"../PlayerManager"
@onready var menu_root : Control = $"../MidPanel"
var players := {}
var player_info := {"-1": {"name": "Name"}}
var players_loaded = 0
var game_scene = preload("res://game.tscn")

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	choice_broadcast.connect(choice_broadcast_test)

func choice_broadcast_test(choice):
	print("received broadcast on %d" % multiplayer.get_unique_id())
	for key in choice:
		print(key)

func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	return "success"

func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	players["1"] = player_info
	player_connected.emit(1, player_info)
	game_joined.emit(1, player_info)

func remove_multiplayer_peer():
	players = {}
	multiplayer.multiplayer_peer = null

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	$"../MidPanel".visible = false
	$"..".add_child(game_scene.instantiate())

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			$/root/Game.start_game()
			players_loaded = 0

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	player_connected.emit(id)

@rpc("any_peer", "call_remote", "reliable")
func transmit_player_data(data):
	if multiplayer.is_server():
		for key in data:
			players[key] = data[key]
		broadcast_player_data.rpc(players)
		player_info_updated.emit()

@rpc("authority", "call_remote", "reliable")
func broadcast_player_data(data):
	players = data
	player_info_updated.emit()

@rpc("any_peer", "call_local", "reliable")
func transmit_player_choice(choice):
	if multiplayer.is_server():
		broadcast_player_choice.rpc(choice)
		choice_broadcast.emit(parse_string_array(choice))

@rpc("authority", "call_remote", "reliable")
func broadcast_player_choice(choice):
	choice_broadcast.emit(parse_string_array(choice))

static func parse_string_array(in_array : Array) -> Array[String]:
	var string_array : Array[String]
	string_array.assign(in_array)
	return string_array

func _on_player_disconnected(id):
	players.erase(str(id))
	player_disconnected.emit(id)
	player_info_updated.emit()

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[str(peer_id)] = player_info
	transmit_player_data.rpc_id(1, players)
	game_joined.emit(peer_id, players)

func _on_connected_fail():
	multiplayer.multiplayer_peer = null
	connection_refused.emit()

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
