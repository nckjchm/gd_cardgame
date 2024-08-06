class_name LobbyManager extends Node

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id)
signal game_joined(peer_id, local_player_info)
signal connection_refused
signal player_disconnected(peer_id)
signal player_info_updated
signal server_disconnected
signal choice_broadcast(choice)
signal game_command(command)

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20
@onready var menu_root : Control = $"../MidPanel"
var lobby_menu : Lobby
var game_manager : GameManager
var players_info := {}
var local_player_info := {"name": "Name", "deck_template" : "TestDeckYellow"}
var game_info := {"field_template": "small_two_player_field1"}
var game_scene = preload("res://game.tscn")
var seats := {}
var seeds : Array[int] = []

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

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
	players_info["1"] = local_player_info
	player_connected.emit(1, local_player_info)
	game_joined.emit(1, local_player_info)
	initialize_seats()
	lobby_menu.redraw()

func initialize_seats():
	var seatcount = Templates.field_templates[game_info.field_template].seats.count
	seats = {}
	for seat_index in range(seatcount):
		seats[str(seat_index)] = { player_key = 0 }

func remove_multiplayer_peer():
	players_info = {}
	game_info = {"field_template": "small_two_player_field1"}
	multiplayer.multiplayer_peer = null

func start_game():
	if is_start_valid():
		load_game.rpc()

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("authority", "call_local", "reliable")
func load_game():
	var taken_seats : Dictionary = {}
	for seat_key in seats:
		if seats[seat_key].player_key != 0:
			taken_seats[seat_key] = { player_key = seats[seat_key].player_key, player_loaded = false}
	game_info.seats = taken_seats
	$"../MidPanel".visible = false
	var game_node = game_scene.instantiate()
	game_manager=game_node.find_child("GameManager")
	$"..".add_child(game_node)

func is_start_valid() -> bool:
	var taken_seats := 0
	for seat in seats:
		if seats[seat].player_key != 0:
			taken_seats += 1
	return taken_seats >= 2

@rpc("any_peer", "call_local", "reliable")
func request_random_seed(seed_index):
	if multiplayer.is_server():
		if len(seeds) < seed_index:
			print("illegal seed index (%d) requested by client %d" % [seed_index, multiplayer.get_remote_sender_id()])
			return
		if len(seeds) == seed_index:
			seeds.append(randi())
		return_random_seed.rpc_id(multiplayer.get_remote_sender_id(), seeds[seed_index])
	
@rpc("authority", "call_local", "reliable")
func return_random_seed(random_seed : int):
	game_manager.random_seeds.append(random_seed)
	game_manager.waiting_for_transmission = false

@rpc("authority", "call_remote", "reliable")
func broadcast_seat_assignment(_seats):
	seats = _seats
	player_info_updated.emit()

@rpc("any_peer", "call_local", "reliable")
func transmit_seat_request(seat_index, leave = false):
	if multiplayer.is_server():
		var seat_assignment_successful := false
		if not leave:
			if seats[str(seat_index)].player_key == 0:
				seats[str(seat_index)].player_key = multiplayer.get_remote_sender_id()
				seat_assignment_successful = true
		else:
			if seats[str(seat_index)].player_key == multiplayer.get_remote_sender_id():
				seats[str(seat_index)].player_key = 0
				seat_assignment_successful = true
		if seat_assignment_successful:
			broadcast_seat_assignment.rpc(seats)
			player_info_updated.emit()

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		var seat_key := ""
		for seat in game_info.seats:
			if game_info.seats[seat].player_key == multiplayer.get_remote_sender_id():
				seat_key = seat
		if seat_key.is_empty():
			print("Observers don't need to call the player_loaded function, client %d misbehaved." % multiplayer.get_remote_sender_id())
			return
		game_info.seats[seat_key].player_loaded = true
		var can_start = true
		for seat in game_info.seats:
			if not game_info.seats[seat].player_loaded:
				can_start = false
		if can_start:
			broadcast_game_command.rpc({type = "start"})

@rpc("authority", "call_local", "reliable")
func broadcast_game_command(command):
	game_command.emit(command)

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	player_connected.emit(id)
	if multiplayer.is_server():
		broadcast_seat_assignment.rpc_id(id, seats)

@rpc("any_peer", "call_remote", "reliable")
func transmit_player_data(data):
	if multiplayer.is_server():
		for key in data:
			players_info[key] = data[key]
		broadcast_player_data.rpc(players_info)
		player_info_updated.emit()

@rpc("authority", "call_remote", "reliable")
func broadcast_player_data(data):
	players_info = data
	player_info_updated.emit()

@rpc("any_peer", "call_local", "reliable")
func transmit_player_choice(choice):
	if multiplayer.is_server():
		if game_manager.is_current_decider_id(multiplayer.get_remote_sender_id()):
			if game_manager.get_choice(parse_string_array(choice)).player_choice_valid:
				broadcast_player_choice.rpc(choice)
				choice_broadcast.emit(LobbyManager.parse_string_array(choice))
			else:
				print("player with id %d tried to make illegal choice" % multiplayer.get_remote_sender_id())
		else:
			print("player with id %d tried to make a choice while it wasnt their turn" % multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func broadcast_player_choice(choice):
	choice_broadcast.emit(LobbyManager.parse_string_array(choice))

static func parse_string_array(in_array : Array) -> Array[String]:
	var string_array : Array[String] = []
	string_array.assign(in_array)
	return string_array

func _on_player_disconnected(id):
	players_info.erase(str(id))
	for seat in seats:
		if seats[seat].player_key == id:
			seats[seat].player_key = 0
	player_disconnected.emit(id)
	player_info_updated.emit()

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players_info[str(peer_id)] = local_player_info
	transmit_player_data.rpc_id(1, players_info)
	game_joined.emit(peer_id, players_info)

func _on_connected_fail():
	multiplayer.multiplayer_peer = null
	connection_refused.emit()

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players_info.clear()
	server_disconnected.emit()
