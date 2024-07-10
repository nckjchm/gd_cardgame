class_name Game

enum TurnPhase { Start, Recovery, Draw1, Main1, Battle, Draw2, Main2, End }
enum ResourceKind { Mana, Nutrition }
enum GameState { Preparation, Hot, Cold, Paused, Finished }

var turns := []
var players : Array[Player]
var turnplayer_seat = 0
var game_state = GameState.Preparation
var current_turn : Turn = null
var hot_action : Action = null
var hot_event : Event = null

func _init(playerList : Array[Player]):
	players = playerList

func start():
	new_turn()
	game_state = GameState.Cold
	
func new_turn():
	turnplayer_seat = (turnplayer_seat + 1) % len(players)
	current_turn = Turn.new(len(turns)+1, players[turnplayer_seat])
	turns.append(current_turn)

func next_player(player : Player):
	return players[(player.seat + 1) % len(players)]

func enter_phase(phase : TurnPhase):
	current_turn.current_phase = phase
	if phase == TurnPhase.Recovery:
		mark_recovery_targets()

func mark_recovery_targets():
	var targets_available := false
	for card in current_turn.turn_player.cards:
		card.needs_recovery = card.check_recovery_viability()
		if card.needs_recovery:
			targets_available = true
	current_turn.recovery_done = not targets_available

func check_recovery_finished():
	for card in current_turn.turn_player.cards:
		if card.needs_recovery:
			return false
	return true

static func next_phase(phase : TurnPhase):
	match phase:
		TurnPhase.Start:
			return TurnPhase.Recovery
		TurnPhase.Recovery:
			return TurnPhase.Draw1
		TurnPhase.Draw1:
			return TurnPhase.Main1
		TurnPhase.Main1:
			return TurnPhase.Battle
		TurnPhase.Battle:
			return TurnPhase.Draw2
		TurnPhase.Draw2:
			return TurnPhase.Main2
		TurnPhase.Main2:
			return TurnPhase.End
		TurnPhase.End:
			return TurnPhase.Start
	print("couldn't match TurnPhase: %s" % phase)

class Turn:
	var turn_number : int
	var turn_player : Player
	var turn_actions := []
	var draw1_drawn := false
	var draw2_drawn := false
	var recovery_done := false
	var current_phase := TurnPhase.Start
	var creature_called := false
	
	func _init(turn_number, turn_player):
		self.turn_number = turn_number
		self.turn_player = turn_player
	
class Deck:
	var name : String
	var main_deck : Array[Card]
	var resource_deck : Array[Card]
	var special_deck : Array[Card]
	var main_deck_templates : Array[CardTemplate]
	var resource_deck_templates : Array[CardTemplate]
	var special_deck_templates : Array[CardTemplate]
	
	func _init(name : String, main : Array[CardTemplate], resource : Array[CardTemplate], special : Array[CardTemplate]):
		self.name = name
		self.main_deck_templates = main
		self.resource_deck_templates = resource
		self.special_deck_templates = special

class ResourceList:
	var elements : Array[ResourceElement]
	
	func _init(resourceList : Array[ResourceElement] = []):
		elements = resourceList
	
	func add(resource : ResourceElement):
		var match_resource = match_element(resource)
		if match_resource != null:
			match_resource.amount += resource.amount
			return true
		elements.append(resource)
		return false
	
	func match_element(resource : ResourceElement):
		for element in elements: 
			if element.color == resource.color and element.kind == resource.kind:
				return element
		return null
	
	func combine(other : ResourceList):
		for element in other.elements:
			add(element)
			
	func subtract(resource : ResourceElement):
		var match_resource = match_element(resource)
		if match_resource != null:
			match_resource.amount -= resource.amount
			if match_resource.amount == 0:
				elements.erase(match_resource)
			return true
		return false
	
	func check_coverage(other : ResourceList, exact := false):
		for element in other.elements:
			var own_element = match_element(element)
			if own_element == null or own_element.amount < element.amount or (exact and own_element.amount > element.amount):
				return false
		return true
	
	func total():
		var total := 0
		for element in elements:
			total += element.amount
		return total
	
	func reduce(resourceList : ResourceList):
		for element in resourceList.elements:
			if not subtract(element):
				print("something went wrong, reduced ResourceList %s by element with kind %s color %s amount %d which didnt exist" % [self.to_string(), element.kind, element.color, element.amount])
	
class ResourceElement:
	var kind : ResourceKind
	var color : Card.CardColor
	var amount : int
	
	func _init(kind : ResourceKind, color : Card.CardColor, amount : int):
		self.kind = kind
		self.color = color
		self.amount = amount
