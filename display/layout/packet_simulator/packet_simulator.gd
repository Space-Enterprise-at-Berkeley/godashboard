extends HBoxContainer
class_name PacketSimulator

@onready var add_function_button: Button = $FunctionGenerator/AddFunction
@onready var function_generator: VBoxContainer = $FunctionGenerator

const function_generator_entry_scene: PackedScene = preload("res://display/layout/packet_simulator/function_generator_entry.tscn")

func _ready() -> void:
	add_function_button.pressed.connect(_add_function)

func setup(config: Dictionary) -> void:
	name = config["name"]

func _add_function() -> void:
	var function_entry = function_generator_entry_scene.instantiate()
	function_generator.add_child(function_entry)
	function_generator.move_child(add_function_button, -1)
