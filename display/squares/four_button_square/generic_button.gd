extends Node
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
@onready var label: Label = $VBoxContainer/HBoxContainer2/ColorRect/Label
@onready var button_safety: CheckButton = $VBoxContainer/ButtonSafety
@onready var time: LineEdit = $VBoxContainer/Time
@onready var color_rect: ColorRect = $VBoxContainer/HBoxContainer2/ColorRect

const button_type_lookup: Dictionary = {
	null: ButtonType.NULL,
	"valve": ButtonType.VALVE,
	"timed": ButtonType.TIMED,
	"switch": ButtonType.SWITCH,
	"ereg": ButtonType.EREG,
	"ereg-timed": ButtonType.EREG_TIMED,
}

var id: String = ""
var field: String = ""
var safe: bool = false
var green: Array = []
var type: ButtonType = ButtonType.NULL
var actions: Dictionary = {}

func _ready() -> void:
	button_close.pressed.connect(_close)
	button_open.pressed.connect(_open)
	button_close_timed.pressed.connect(_partial_close)
	button_open_timed.pressed.connect(_partial_open)
	button_safety.toggled.connect(_switch_safety)

func setup(config: Dictionary) -> void:
	type = button_type_lookup[config["type"]]
	if type == ButtonType.NULL:
		color_rect.hide()
		return
	label.text = config.get("name", "")
	id = config.get("id", "")
	field = config.get("field", false)
	safe = config.get("safe", false)
	green = config.get("green", [])
	actions = config.get("actions", {})
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
			pass
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

func _execute_action(action: Dictionary) -> void:
	if action.get("type", null) == null:
		return
	var t: float
	var t_valid: bool = false
	if time.text.is_valid_float():
		t_valid = true
		t = time.text.to_float()
	var target: Array = Config.config["commandMap"][action["target"]]
	var board: String = target[0]
	var packet: int = target[1]
	var number: Variant = target[2]
	match action["type"]:
		case "retract-full":
			if number != null:
				Databus.send_packet()
