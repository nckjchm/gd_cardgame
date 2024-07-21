class_name MainMenu extends Control

@onready var btn_new_game : Button = $MidPanel/MidPanelVBox/NewGame
var game_scene = preload("res://game.tscn")

func _ready():
	btn_new_game.pressed.connect(func():
		$/root.add_child(game_scene.instantiate())
		self.queue_free()
	)
