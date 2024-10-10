extends HBoxContainer
class_name Header

@onready var boards: HBoxContainer = $Boards
@onready var settings_button: Button = $MarginContainer/CenterContainer/SettingsButton
@onready var settings_menu: SettingsMenu = $SettingsMenu

const board_status_scene: PackedScene = preload("res://display/header/board_status.tscn")

func _ready() -> void:
	Config.config_update.connect(_config_update)
	if Config.exists:
		_config_update()
	settings_button.pressed.connect(_show_settings_menu)

func _config_update() -> void:
	for child in boards.get_children():
		child.queue_free()
	for board: String in Config.config["boards"].values():
		var board_status: BoardStatus = board_status_scene.instantiate()
		boards.add_child(board_status)
		board_status.setup(board)

func _show_settings_menu() -> void:
	settings_menu.display()
