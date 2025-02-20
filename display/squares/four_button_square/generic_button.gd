extends Control
class_name GenericButton

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
@onready var disable_container: MarginContainer = $VBoxContainer/HBoxContainer3/DisableContainer
@onready var enable_container: MarginContainer = $VBoxContainer/HBoxContainer3/EnableContainer

const BUTTON_ENABLE: String = "buttonΕnable"
const BUTTON_DISABLE: String = "buttonDisable"

const BUTTON_COLOR_ON: Color = Color(0.0, 1.0, 0.0)
const BUTTON_COLOR_OFF: Color = Color.TRANSPARENT

var id: String = ""
var field: String = ""
var safe: Array[Button] = []
var shortcuts: Dictionary = {}
var reverse_shortcuts: Dictionary = {}
var green: Array = []
var actions: Dictionary = {}
var shortcut_labels: Dictionary = {}

func _ready() -> void:
	color_rect.color = BUTTON_COLOR_OFF
	button_close.pressed.connect(_close)
	button_open.pressed.connect(_open)
	button_close_timed.pressed.connect(_partial_close)
	button_open_timed.pressed.connect(_partial_open)
	button_safety.toggled.connect(_switch_safety)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.shift_pressed:
			if shortcuts.has(event.keycode):
				var button: Button = shortcuts[event.keycode]
				if button.visible and not button.disabled:
					var focus: Control = get_viewport().gui_get_focus_owner()
					if focus is TextEdit or focus is LineEdit or focus is GraphEdit:
						return
					button.pressed.emit()

func setup(config: Dictionary, is_null: bool) -> void:
	if is_null:
		color_rect.hide()
		return
	label.text = config.get("name", "")
	id = config.get("id", "")
	field = config.get("field", "")
	green = config.get("green", [])
	actions = config.get("actions", {})
	Databus.register_callback(BUTTON_ENABLE, get_window(), _handle_packet_enable, true)
	Databus.register_callback(BUTTON_DISABLE, get_window(), _handle_packet_disable, true)
	Databus.register_callback(field, get_window(), _handle_packet_value)
	shortcut_labels = {
		button_close_timed: [disable_key, disable_container],
		button_open_timed: [enable_key, enable_container],
	}
	for action_type: String in actions:
		var action: Dictionary = actions[action_type]
		var current_button: Button = null
		match action_type:
			"open": current_button = button_open
			"close": current_button = button_close
			"open-partial": current_button = button_open_timed
			"close-partial": current_button = button_close_timed
			"switch-enable": current_button = button_safety
			"switch-disable": current_button = button_safety
			_: continue
		current_button.show()
		if action.get("safe", false):
			safe.append(current_button)
			button_safety.show()
		if action.has("shortcut"):
			shortcuts[action["shortcut"]] = current_button
			reverse_shortcuts[current_button] = action["shortcut"]
			if shortcut_labels.has(current_button):
				shortcut_labels[current_button][0].text = OS.get_keycode_string(action["shortcut"]).to_upper()
				shortcut_labels[current_button][1].show()
		if _requires_input(action):
			time.show()
	_disable()

func _requires_input(action: Variant) -> bool:
	if typeof(action) == TYPE_STRING:
		return action == "<input>"
	elif typeof(action) == TYPE_DICTIONARY:
		return (action as Dictionary).values().any(_requires_input)
	elif typeof(action) == TYPE_ARRAY:
		return (action as Array).any(_requires_input)
	return false

func _open() -> void:
	_execute_action(actions["open"])

func _close() -> void:
	_execute_action(actions["close"])

func _partial_open() -> void:
	_execute_action(actions["open-partial"])

func _partial_close() -> void:
	_execute_action(actions["close-partial"])

func _switch_safety(enabled: bool) -> void:
	if enabled:
		if actions.has("switch-enable"):
			_execute_action(actions["switch-enable"])
		_enable()
	else:
		if actions.has("switch-disable"):
			_execute_action(actions["switch-disable"])
		_disable()

func _enable() -> void:
	for button in safe:
		button.disabled = false

func _disable() -> void:
	for button in safe:
		button.disabled = true

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
	if not action.has("type"):
		Logger.error("No action type specified")
		return
	match action.get("type"):
		"packet":
			Databus.validate_and_send(_replace_input(action.get("board", "?")), _replace_input(action["packet"]), _replace_input(action["args"]))
		"targeted-abort":
			Databus.validate_and_send(_replace_input(action["board"]), "Abort", _replace_input({
				"systemMode": Config.config["mode"],
				"abortReason": action.get("reason", "MANUAL")
			}))
		"enable":
			Databus.send_update({BUTTON_ENABLE: action["id"]}, Databus.get_current_time())
		"disable":
			Databus.send_update({BUTTON_DISABLE: action["id"]}, Databus.get_current_time())

func _replace_input(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING:
			return _get_time_float() if value == "<input>" else value
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key: String in value:
				out[key] = _replace_input(value[key])
			return out
		TYPE_ARRAY:
			return (value as Array).map(_replace_input)
	return value

# Old button system. Some functions can probably be salvaged
#func _execute_action(action: Dictionary) -> void:
	#Logger.info(action)
	#if action.get("type", null) == null:
		#return
	#var target: Array
	#var board: String
	#var packet: int
	#var number: Variant
	#if action.has("target"):
		#target = Config.config["commandMap"][action["target"]]
		#board = target[0]
		#packet = target[1]
		#number = target[2]
	#match action["type"]:
		#"retract-full":
			#Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(0), Databus.make_uint32(0)])
		#"extend-full":
			#Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(1), Databus.make_uint32(0)])
		#"retract-timed":
			#Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(2), Databus.make_uint32(_get_time_int())])
		#"extend-timed":
			#Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(3), Databus.make_uint32(_get_time_int())])
		#"on":
			#Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(4), Databus.make_uint32(0)])
		#"off":
			#Databus.send_packet(board, packet, [Databus.make_uint8(number), Databus.make_uint8(5), Databus.make_uint32(0)])
		#"enable":
			#Databus.send_update({BUTTON_ENABLE: action["id"]}, Databus.get_current_time())
		#"disable":
			#Databus.send_update({BUTTON_DISABLE: action["id"]}, Databus.get_current_time())
		#"signal":
			#Databus.send_packet(board, packet, [])
		#"signal-timed":
			#Databus.send_packet(board, packet, [Databus.make_float(_get_time_float())])
		#"start-pings":
			#Pings.add_ping(action["pingId"], func () -> void: Databus.send_packet(board, packet, []), action["delay"])
		#"stop-pings":
			#Pings.remove_ping(action["pingId"])
		#"zero":
			#Databus.send_packet(board, packet, [Databus.make_uint8(_get_time_int())])
		#"enable-heartbeat":
			#Globals.heartbeat_enabled = true
		#"disable-heartbeat":
			#Globals.heartbeat_enabled = false
		#"signal":
			#Databus.send_packet(board, packet, [])
		#"signal-timed":
			#Databus.send_packet(board, packet, [Databus.make_float(_get_time_float())])
		#"start-pings":
			#Pings.add_ping(action["pingId"], func () -> void: Databus.send_packet(board, packet, []), action["delay"])
		#"stop-pings":
			#Pings.remove_ping(action["pingId"])
		#"zero":
			#Databus.send_packet(board, packet, [Databus.make_uint8(_get_time_int())])
		#"enable-heartbeat":
			#Databus.send_packet("bcast", 251, [Databus.make_uint8(1)])
		#"disable-heartbeat":
			#Databus.send_packet("bcast", 251, [Databus.make_uint8(0)])

func update_status_bar(value: Variant) -> void:
	value = Config.config["reverse_enum_lookup"]["ACActuatorStatesType"][value]
	if green.has(value):
		color_rect.color = BUTTON_COLOR_ON
	else:
		color_rect.color = BUTTON_COLOR_OFF

func _handle_packet_enable(value: String, timestamp: int) -> void:
	if value == id:
		_enable()

func _handle_packet_disable(value: String, timestamp: int) -> void:
	if value == id:
		_disable()

func _handle_packet_value(value: Variant, timestamp: int) -> void:
	update_status_bar(value)
