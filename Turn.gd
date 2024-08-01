class_name Turn

enum TurnPhase { Start, Recovery, Draw1, Main1, Battle, Draw2, Main2, End }

var turn_number : int
var turn_player : Player
var turn_actions := []
var draw1_drawn := false
var draw2_drawn := false
var recovery_done := false
var current_phase := TurnPhase.Start
var creature_called := false

func _init(_turn_number, _turn_player):
	turn_number = _turn_number
	turn_player = _turn_player
