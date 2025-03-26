extends PanelContainer
class_name CalibrationEntry

@onready var updating_field: SixValueSquareField = $HBoxContainer/MarginContainer/VBoxContainer/UpdatingField
@onready var graph_square: GraphSquare = $HBoxContainer/GraphSquare
@onready var enable_button: CheckButton = $HBoxContainer/MarginContainer/VBoxContainer/EnableButton
@onready var first_point_button: Button = $HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/FirstPointButton
@onready var second_point_button: Button = $HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SecondPointButton
@onready var value_input: LineEdit = $HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ValueInput
@onready var reset_button: Button = $HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ResetButton

var board: String = ""
var channel: int = 0
var first_point_packet: Dictionary = {}
var second_point_packet: Dictionary = {}
var reset_packet: Dictionary = {}

func setup(config: Dictionary) -> void:
	board = config["board"]
	channel = config["channel"]
	first_point_packet = config["firstPoint"]
	second_point_packet = config["secondPoint"]
	reset_packet = config["reset"]
	first_point_button.disabled = true
	second_point_button.disabled = true
	reset_button.disabled = true
	updating_field.setup({
		"field": config["field"],
		"name": config["name"],
		"units": config["units"]
	}, false)
	graph_square.setup({
		"values": [
			{
				"field": config["field"],
				"name": config["name"],
				"units": config["units"],
				"color": config["color"]
			}
		]
	})
	enable_button.toggled.connect(_on_enable_button)
	first_point_button.pressed.connect(_on_send_point.bind(first_point_packet))
	second_point_button.pressed.connect(_on_send_point.bind(second_point_packet))
	reset_button.pressed.connect(_on_send_point.bind(reset_packet))

func _on_enable_button(state: bool) -> void:
	first_point_button.disabled = not state
	second_point_button.disabled = not state
	reset_button.disabled = not state

func _on_send_point(packet: Dictionary) -> void:
	var args: Dictionary = {}
	for arg: String in packet["args"]:
		var value: Variant = packet["args"][arg]
		if value is not String:
			args[arg] = value
		elif value == "<channel>":
			args[arg] = channel
		elif value == "<input>":
			args[arg] = value_input.text.to_float()
		else:
			args[arg] = value
	Databus.validate_and_send(board, packet["packet"], args)
