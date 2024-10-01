class_name PauseMenu extends PanelContainer

@onready var btn_resume : Button = $VLayout/Resume
@onready var btn_exit : Button = $VLayout/Exit
var gui : GUIController

func initialize(_gui : GUIController):
	gui = _gui

func _ready():
	btn_resume.pressed.connect(close)
	btn_exit.pressed.connect(exit)

func exit():
	close()
	gui.game_manager.lobby_manager.exit_game()

func close():
	gui.close_pause_menu()
