class_name Lobby extends Control

@onready var players_container : GridContainer = $ConnectedPlayers
@onready var seats_container : GridContainer = $Seats
@onready var btn_start : Button = $StartGame
@onready var btn_exit : Button = $Exit
@onready var lobby_manager : LobbyManager = $"../../LobbyManager"
@onready var btn_deck_select : OptionButton = $DeckSelect
var players_info : Array[Player]
var player_name_labels : Array[Label]
var player_id_labels : Array[Label]

func _ready():
	btn_start.pressed.connect(func():
		lobby_manager.start_game()
	)
	btn_exit.pressed.connect(func():
		lobby_manager.remove_multiplayer_peer()
		close()
	)
	lobby_manager.player_info_updated.connect(func():
		redraw()
	)
	btn_deck_select.get_popup().index_pressed.connect(func(index : int):
		lobby_manager.local_player_info.deck_template = btn_deck_select.get_item_text(index)
		lobby_manager.build_player_deck_info()
		lobby_manager.update_player_data()
	)
	for deck_template in Templates.deck_templates:
		btn_deck_select.add_item(deck_template)
	lobby_manager.server_disconnected.connect(close)
	btn_start.disabled = true
	redraw()

func redraw():
	empty()
	reparse_players()
	for player in players_info:
		add_connected_player_row(player)
	for seat_key in lobby_manager.seats:
		draw_seat_info(seat_key)
	check_start_viability()

func check_start_viability():
	if multiplayer.is_server() and lobby_manager.is_start_valid():
		btn_start.disabled = false
	else:
		btn_start.disabled = true

func empty():
	for child in players_container.get_children():
		if child.get_index() > 1:
			players_container.remove_child(child)
	for child in seats_container.get_children():
		if child.get_index() > 2:
			seats_container.remove_child(child)

func reparse_players():
	players_info = []
	for key in lobby_manager.players_info:
		var local_player_info = lobby_manager.players_info[key]
		var new_player := Player.new(local_player_info.name)
		new_player.session_id = int(key)
		new_player.seat = -1
		var new_player_deck_template = DeckTemplate.new(
			local_player_info.deck.name, 
			GameUtil.parse_string_array(local_player_info.deck.maindeck), 
			GameUtil.parse_string_array(local_player_info.deck.resourcedeck), 
			GameUtil.parse_string_array(local_player_info.deck.specialdeck))
		new_player.deck = Deck.new(new_player_deck_template, local_player_info.deck.name)
		players_info.append(new_player)

func add_connected_player_row(player : Player):
	var id_label := Label.new()
	id_label.text = str(player.session_id)
	player_id_labels.append(id_label)
	players_container.add_child(id_label)
	var name_label := Label.new()
	name_label.text = player.name
	player_name_labels.append(name_label)
	players_container.add_child(name_label)

func draw_seat_info(seat_index):
	var seat_key := str(seat_index)
	var seat_id_label := Label.new()
	seat_id_label.text = seat_key
	var player_name_label := Label.new()
	var player_key = str(lobby_manager.seats[seat_key].player_key)
	player_name_label.text = lobby_manager.players_info[player_key].name if player_key != "0" and player_key in lobby_manager.players_info else "Empty"
	var choose_button = Button.new()
	choose_button.text = "Choose"
	if player_key != "0":
		choose_button.disabled = true
	else:
		choose_button.pressed.connect(func(): lobby_manager.transmit_seat_request.rpc_id(1, seat_key))
	if player_key == str(multiplayer.get_unique_id()):
		choose_button.text = "Leave"
		choose_button.pressed.connect(func(): lobby_manager.transmit_seat_request.rpc_id(1, seat_key, true))
		choose_button.disabled = false
	for other_seat_index in lobby_manager.seats:
		if str(lobby_manager.seats[str(other_seat_index)].player_key) == str(multiplayer.get_unique_id()) and other_seat_index != seat_index:
			choose_button.text = ""
			choose_button.disabled = true
	seats_container.add_child(seat_id_label)
	seats_container.add_child(player_name_label)
	seats_container.add_child(choose_button)

func close():
	var main_menu : VBoxContainer = $"../MainMenuVB"
	main_menu.visible = true
	self.queue_free()
