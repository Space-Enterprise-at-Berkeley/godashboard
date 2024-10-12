extends HBoxContainer
class_name Header

@onready var frame_rate: Label = $FrameRateContainer/MarginContainer/FrameRate
@onready var flow_time: Label = $FlowTimeContainer/MarginContainer/FlowTime
@onready var influx: Label = $InfluxContainer/MarginContainer/Influx
@onready var boards: HBoxContainer = $Boards
@onready var settings_button: Button = $MarginContainer/CenterContainer/SettingsButton
@onready var settings_menu: SettingsMenu = $SettingsMenu

const board_status_scene: PackedScene = preload("res://display/header/board_status.tscn")

func _ready() -> void:
	Config.config_update.connect(_config_update)
	Influx.database_change.connect(_set_influx_text)
	Influx.influx_error.connect(_set_influx_text)
	if Config.exists:
		_config_update()
	settings_button.pressed.connect(_show_settings_menu)

func _process(delta: float) -> void:
	frame_rate.text = "%d FPS" % int(Engine.get_frames_per_second())

func _config_update() -> void:
	for child in boards.get_children():
		child.queue_free()
	for board: String in Config.config["boards"].values():
		if board.begins_with("GD"):
			continue
		var board_status: BoardStatus = board_status_scene.instantiate()
		boards.add_child(board_status)
		board_status.setup(board)
	flow_time.text = "%d ms" % Config.config["burnTime"]

func _show_settings_menu() -> void:
	settings_menu.display()

func _set_influx_text(msg: String) -> void:
	influx.text = msg
