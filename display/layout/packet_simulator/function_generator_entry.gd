extends PanelContainer
class_name FunctionGeneratorEntry

@onready var delete_button: Button = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Delete
@onready var delay: LineEdit = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Delay
@onready var enabled_button: CheckButton = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Enabled
@onready var update_button: Button = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Update
@onready var function_text: LineEdit = $MarginContainer/FunctionGeneratorEntry/FunctionText
@onready var packet_editor: PacketEditor = $MarginContainer/FunctionGeneratorEntry/PacketEditor
@onready var timer: Timer = $Timer

# Floating point moment
const TIME_MODULO: int = 10000000

var expression: Expression = Expression.new()
var expression_valid: bool = false
var variables: PackedStringArray = PackedStringArray(["t"])
var packet_simulator: PacketSimulator
var command: String = ""

func _ready() -> void:
	delete_button.pressed.connect(queue_free)
	timer.timeout.connect(_execute)
	update_button.pressed.connect(_update)

func _delete() -> void:
	queue_free()

func _update() -> void:
	expression_valid = expression.parse(function_text.text, variables) == OK
	command = packet_editor.text_edit.text
	timer.wait_time = delay.text.to_float() / 1000.0

func _execute() -> void:
	if not expression_valid or not enabled_button.button_pressed:
		return
	var timestamp: int = Databus.get_current_time()
	var value: Variant = expression.execute([float(timestamp % TIME_MODULO)])
	packet_simulator.parse_and_send(command.replace("@", str(value)))
