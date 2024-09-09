class_name DeckEditor extends Control

@onready var maindeck_container : HFlowContainer = $HLayout/ScrollContainer/MidContent/MainDeck/VLayout/CardContainer
@onready var resourcedeck_container : HFlowContainer = $HLayout/ScrollContainer/MidContent/ResourceDeck/VBoxContainer/CardContainer
@onready var specialdeck_container : HFlowContainer = $HLayout/ScrollContainer/MidContent/SpecialDeck/VBoxContainer/CardContainer
@onready var lobby_manager : LobbyManager = $"../LobbyManager"
@onready var name_filter : LineEdit = $HLayout/RightSideMenu/VLayout/NameFilter
@onready var search_container : VBoxContainer = $HLayout/RightSideMenu/VLayout/CardScrollContonainer/CardVLayout
@onready var btn_search : Button = $HLayout/RightSideMenu/VLayout/SearchButton
@onready var btn_save : Button = $HLayout/LeftSideMenu/VLayout/Save
@onready var btn_load : Button = $HLayout/LeftSideMenu/VLayout/Load
@onready var btn_delete : Button = $HLayout/LeftSideMenu/VLayout/Delete
@onready var btn_exit : Button = $HLayout/LeftSideMenu/VLayout/Exit
@onready var deck_name : LineEdit = $HLayout/LeftSideMenu/VLayout/DeckName

var deck_containers : Array[HFlowContainer]
var dragging := false
var card_placeholder_template = preload("res://card_placeholder.tscn")

func _ready():
	btn_exit.pressed.connect(func():
		get_parent().close_deck_editor()
	)
	btn_load.pressed.connect(func():
		load_deck(deck_name.text)
	)
	btn_save.pressed.connect(save_deck)
	btn_delete.pressed.connect(delete_deck)
	btn_search.pressed.connect(update_card_search)
	deck_containers = [maindeck_container, resourcedeck_container, specialdeck_container]
	load_deck(lobby_manager.local_player_info.deck_template)
	update_card_search()

func load_deck(deck_name : String):
	if not deck_name in Templates.deck_templates:
		return
	clear_deck_display()
	var deck_template : DeckTemplate = Templates.deck_templates[deck_name]
	for deck_container in deck_containers:
		var deck_keys = deck_template.main_deck_keys
		if deck_container == specialdeck_container:
			deck_keys = deck_template.special_deck_keys
		elif deck_container == resourcedeck_container:
			deck_keys = deck_template.resource_deck_keys
		for deck_key in deck_keys:
			deck_container.add_child(create_card_display(Templates.templates[deck_key]))
		var card_placeholder : CardPlaceholder = card_placeholder_template.instantiate()
		deck_container.add_child(card_placeholder)
		card_placeholder.data_drop_received.connect(on_data_drop_received)

func update_card_search():
	clear_card_search()
	var search_results : Array[CardTemplate] = []
	for template_key in Templates.templates:
		var card_template : CardTemplate = Templates.templates[template_key]
		if filters_match_template(card_template):
			search_results.append(card_template)
	for result in search_results:
		search_container.add_child(create_card_display(result))

func create_card_display(template : CardTemplate):
	var card_gui_display : CardGUIDisplay = Templates.card_gui_display_prefab.instantiate()
	card_gui_display.from_template(template)
	card_gui_display.drag_started.connect(on_drag_started)
	card_gui_display.data_drop_received.connect(on_data_drop_received)
	return card_gui_display

func clear_card_search():
	for card_gui_display in search_container.get_children():
		card_gui_display.queue_free()

func filters_match_template(template : CardTemplate):
	return name_filter.text.is_empty() or template.name.contains(name_filter.text)

func save_deck():
	print("saving deck %s" % deck_name.text)
	var file_name = "user://decks/%s.tcgdeck" % deck_name.text
	var deck_file = FileAccess.open(file_name, FileAccess.WRITE)
	var serialized_deck = serialize_deck()
	if deck_file is FileAccess:
		deck_file.store_line(JSON.stringify(serialized_deck))
		deck_file.close()
		Templates.save_deck_template(DeckTemplate.from_serialized(serialized_deck))

func serialize_deck():
	var deck_lists := []
	for deck_container in deck_containers:
		var deck_list : Array[String] = []
		for card_display in deck_container.get_children():
			if card_display is CardGUIDisplay:
				deck_list.append(card_display.card_display.card_template.key)
		deck_lists.append(deck_list)
	return {
		"name" : deck_name.text,
		"main" : deck_lists[0],
		"resource" : deck_lists[1],
		"special" : deck_lists[2]
	}

func delete_deck():
	var file_path = "user://decks/%s.tcgdeck" % deck_name.text
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		Templates.remove_deck_template(deck_name.text)

func clear_deck_display():
	for deck_container in deck_containers:
		for card_gui_display in deck_container.get_children():
			card_gui_display.queue_free()

func on_drag_started(dragged : CardGUIDisplay):
	set_drag_preview(create_card_display(dragged.card_display.card_template))
	if dragged.get_parent() != search_container:
		dragged.get_parent().remove_child(dragged)

func on_data_drop_received(recipient : Control, data):
	if data is CardGUIDisplay:
		if recipient.get_parent() in deck_containers:
			var context := recipient.get_parent()
			var new_card_index := recipient.get_index()
			var existing_cards = context.get_children()
			for existing_card in existing_cards:
				context.remove_child(existing_card)
			for index_iter in range(len(existing_cards)):
				if index_iter == new_card_index:
					context.add_child(create_card_display(data.card_display.card_template))
				context.add_child(existing_cards[index_iter])
		
