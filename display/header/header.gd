extends HBoxContainer
class_name Header

@onready var frame_rate: Label = $FrameRateContainer/MarginContainer/FrameRate
@onready var flow_time: Label = $FlowTimeContainer/MarginContainer/FlowTime
@onready var influx: Label = $InfluxContainer/MarginContainer/Influx
@onready var boards: HBoxContainer = $Boards
@onready var settings_button: Button = $MarginContainer/CenterContainer/SettingsButton
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var lock_button: Button = $PacketLockButton

const board_status_scene: PackedScene = preload("res://display/header/board_status.tscn")
const locked_icon: Texture2D = preload("res://resources/icon/lock.svg")
const unlocked_icon: Texture2D = preload("res://resources/icon/unlock.svg")

func _ready() -> void:
	Config.config_update.connect(_config_update)
	Influx.database_change.connect(_set_influx_text)
	Influx.influx_error.connect(_set_influx_text)
	Databus.lock_update.connect(_update_icon)
	if Config.exists:
		_config_update()
	settings_button.pressed.connect(_show_settings_menu)
	lock_button.pressed.connect(Databus.toggle_lock)
	_update_icon(Databus.packet_locked)

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

func _update_icon(state: bool) -> void:
	if state :
		lock_button.icon = locked_icon
	else :
		lock_button.icon = unlocked_icon
