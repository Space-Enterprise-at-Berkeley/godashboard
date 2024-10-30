extends Control
class_name GenericButton

enum ButtonType {
	NULL,
	VALVE,
	TIMED,
	SWITCH,
	EREG,
	EREG_TIMED,
}

@onready var button_close: Button = $VBoxContainer/HBoxContainer/ButtonClose
@onready var button_open: Button = $VBoxContainer/HBoxContainer/ButtonOpen
@onready var button_close_timed: Button = $VBoxContainer/HBoxContainer2/ButtonCloseTimed
@onready var button_open_timed: Button = $VBoxContainer/HBoxContainer2/ButtonOpenTimed
@onready var label: Label = $VBoxContainer/HBoxContainer2/ColorRect/MarginContainer/ColorRect/Label
@onready var button_safety: CheckButton = $VBoxContainer/ButtonSafety
@onready var time: LineEdit = $VBoxContainer/HBoxContainer3/Time
@onready var color_rect: ColorRect = $VBoxContainer/HBoxContainer2/ColorRect
@onready var disable_key: Label = $VBoxContainer/HBoxContainer3/DisableContainer/DisableKey
@onready var enable_key: Label = $VBoxContainer/HBoxContainer3/EnableContainer/EnableKey

const BUTTON_TYPE_LOOKUP: Dictionary = {
	null: ButtonType.NULL,
	"valve": ButtonType.VALVE,
	"timed": ButtonType.TIMED,
	"switch": ButtonType.SWITCH,
	"ereg": ButtonType.EREG,
	"ereg-timed": ButtonType.EREG_TIMED,
}

const BUTTON_ENABLE: String = "buttonΕnable"
const BUTTON_DISABLE: String = "buttonDisable"

const BUTTON_COLOR_ON: Color = Color(0.0, 1.0, 0.0)
const BUTTON_COLOR_OFF: Color = Color.TRANSPARENT

var id: String = ""
var field: String = ""
var safe: bool = false
var green: Array = []
var type: ButtonType = ButtonType.NULL
var actions: Dictionary = {}
var key_enable: int = -2
var key_disable: int = -2

func _ready() -> void:
	color_rect.color = BUTTON_COLOR_OFF
	button_close.pressed.connect(_close)
	button_open.pressed.connect(_open)
	button_close_timed.pressed.connect(_partial_close)
	button_open_timed.pressed.connect(_partial_open)
	button_safety.toggled.connect(_switch_safety)
	Databus.update.connect(_handle_packet)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.shift_pressed:
			if event.keycode == key_enable and button_open_timed.visible and not button_open_timed.disabled:
				_partial_open()
			elif event.keycode == key_disable and button_close_timed.visible and not button_close_timed.disabled:
				_partial_close()

func setup(config: Dictionary) -> void:
	type = BUTTON_TYPE_LOOKUP[config["type"]]
	if type == ButtonType.NULL:
		color_rect.hide()
		return
	label.text = config.get("name", "")
	id = config.get("id", "")
	field = config.get("field", false)
	safe = config.get("safe", false)
	green = config.get("green", [])
	actions = config.get("actions", {})
	if config.has("keyEnable"):
		key_enable = config["keyEnable"]
		enable_key.text = OS.get_keycode_string(key_enable)
	if config.has("keyDisable"):
		key_disable = config["keyDisable"]
		disable_key.text = OS.get_keycode_string(key_disable)
	if safe:
		button_safety.show()
		_disable()
	match type:
		ButtonType.VALVE:
			button_close.show()
			button_open.show()
		ButtonType.TIMED:
			button_close.show()
			button_open.show()
			button_close_timed.show()
			button_open_timed.show()
			time.show()
		ButtonType.SWITCH:
			button_safety.show()
		ButtonType.EREG:
			button_close.show()
			button_open.show()
		ButtonType.EREG_TIMED:
			button_close_timed.show()
			button_open_timed.show()
			time.show()

func _open() -> void:
	match type:
		ButtonType.VALVE, ButtonType.TIMED:
			_execute_action(actions["enable"])
		ButtonType.EREG:
			_execute_action(actions["fuel"])

func _close() -> void:
	match type:
		ButtonType.VALVE, ButtonType.TIMED:
			_execute_action(actions["disable"])
		ButtonType.EREG:
			_execute_action(actions["lox"])

func _partial_open() -> void:
	match type:
		ButtonType.TIMED:
			_execute_action(actions["enable-timed"])
		ButtonType.EREG_TIMED:
			_execute_action(actions["fuel-timed"])

func _partial_close() -> void:
	match type:
		ButtonType.TIMED:
			_execute_action(actions["disable-timed"])
		ButtonType.EREG_TIMED:
			_execute_action(actions["lox-timed"])

func _switch_safety(enabled: bool) -> void:
	match type:
		ButtonType.SWITCH:
			if enabled:
				_execute_action(actions["enable"])
			else:
				_execute_action(actions["disable"])
		_:
			if enabled:
				_enable()
			else:
				_disable()

func _enable() -> void:
	button_open.disabled = false
	button_close.disabled = false
	button_open_timed.disabled = false
	button_close_timed.disabled = false

func _disable() -> void:
	match type:
		ButtonType.VALVE, ButtonType.TIMED:
			button_open.disabled = true
			button_open_timed.disabled = true
		ButtonType.EREG, ButtonType.EREG_TIMED:
			button_open.disabled = true
			button_close.disabled = true
			button_open_timed.disabled = true
			button_close_timed.disabled = true

func _get_time_int() -> int:
	var t: int = 0
	if time.text.is_valid_int():
		t = time.text.to_int()
	return t

func _get_time_float() -> float:
	var t: float = 0.0
	if time.text.is_valid_float():
		t = time.text.to_float()
	return t

func _execute_action(action: Dictionary) -> void:
	if action.get("type", null) == null:
		return
	var target: Array
	var board: String
	var packet: int
	var number: Variant
	if action.has("target"):
		target = Config.config["commandMap"][action["target"]]
		board = target[0]
		packet = target[1]
		number = target[2]
	match action["type"]:
		"retract-full":
			Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(0), Databus.make_uint32(0)])
		"extend-full":
			Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(1), Databus.make_uint32(0)])
		"retract-timed":
			Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(2), Databus.make_uint32(_get_time_int())])
		"extend-timed":
			Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(3), Databus.make_uint32(_get_time_int())])
		"on":
			Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(4), Databus.make_uint32(0)])
		"off":
			Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(5), Databus.make_uint32(0)])
		"enable":
			Databus.send_update({BUTTON_ENABLE: action["id"]}, Databus.get_current_time())
		"disable":
			Databus.send_update({BUTTON_DISABLE: action["id"]}, Databus.get_current_time())
		"signal":
			Databus.send_packet(board, packet, [])
		"signal-timed":
			Databus.send_packet(board, packet, [Databus.make_float(_get_time_float())])
		"start-pings":
			Pings.add_ping(action["pingId"], func () -> void: Databus.send_packet(board, packet, []), action["delay"])
		"stop-pings":
			Pings.remove_ping(action["pingId"])
		"zero":
			Databus.send_packet(board, packet, [Databus.make_uint8(_get_time_int())])
		"enable-heartbeat":
			Databus.send_packet("bcast", 251, [Databus.make_uint8(1)])
		"disable-heartbeat":
			Databus.send_packet("bcast", 251, [Databus.make_uint8(0)])

func update_status_bar(value: Variant) -> void:
	if green.has(value):
		color_rect.color = BUTTON_COLOR_ON
	else:
		color_rect.color = BUTTON_COLOR_OFF

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	if fields.get(BUTTON_ENABLE, null) == id:
		_enable()
	elif fields.get(BUTTON_DISABLE, null) == id:
		_disable()
	if fields.has(field):
		update_status_bar(fields[field])
