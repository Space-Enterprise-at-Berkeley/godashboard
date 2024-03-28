extends HBoxContainer
class_name PacketSimulator

@onready var add_function_button: Button = $FunctionGenerator/AddFunction
@onready var function_generator: VBoxContainer = $FunctionGenerator
@onready var packet_cli: PacketEditor = $PacketCLI/PacketEditor
@onready var packet_cli_history_display: RichTextLabel = $PacketCLI/PanelContainer/PacketCLIHistory

const function_generator_entry_scene: PackedScene = preload("res://display/layout/packet_simulator/function_generator_entry.tscn")
const packet_editor_scene: PackedScene = preload("res://display/layout/packet_simulator/packet_editor.tscn")

func _ready() -> void:
	add_function_button.pressed.connect(_add_function)
	packet_cli.submit.connect(_packet_cli_submit)

func setup(config: Dictionary) -> void:
	name = config["name"]

func _add_function() -> void:
	var function_entry: FunctionGeneratorEntry = function_generator_entry_scene.instantiate()
	function_entry.packet_simulator = self
	function_generator.add_child(function_entry)
	function_generator.move_child(add_function_button, -1)

func _packet_cli_submit() -> void:
	var text: String = packet_cli.text_edit.text
	parse_and_send(text)
	var tokens: PackedStringArray = text.split(" ")
	for i in tokens.size():
		if i == 0:
			packet_cli_history_display.push_color(Globals.theme.get_color("packet_editor_ip", "Global"))
			packet_cli_history_display.add_text(tokens[i])
		elif i == 1:
			packet_cli_history_display.pop()
			packet_cli_history_display.push_color(Globals.theme.get_color("packet_editor_id", "Global"))
			packet_cli_history_display.add_text(tokens[i])
		else:
			packet_cli_history_display.pop()
			packet_cli_history_display.push_color(Globals.theme.get_color("packet_editor_value", "Global"))
			packet_cli_history_display.add_text(tokens[i])
		if i != tokens.size() - 1:
			packet_cli_history_display.add_text(" ")
	packet_cli_history_display.pop()
	packet_cli_history_display.newline()

func parse_and_send(text: String) -> void:
	var tokens: PackedStringArray = text.split(" ")
	if tokens.size() < 2 or not tokens[1].is_valid_int():
		return
	var args: Array = []
	var i: int = 2
	while i < tokens.size():
		var token: String = tokens[i]
		if token.ends_with("f"):
			args.append([token.substr(0, token.length() - 1).to_float(), Databus.PacketDataType.FLOAT])
		elif token.ends_with("u8"):
			args.append([token.substr(0, token.length() - 2).to_int(), Databus.PacketDataType.UINT8])
		elif token.ends_with("u16"):
			args.append([token.substr(0, token.length() - 3).to_int(), Databus.PacketDataType.UINT16])
		elif token.ends_with("u32"):
			args.append([token.substr(0, token.length() - 3).to_int(), Databus.PacketDataType.UINT32])
		i += 1
	Databus.send_packet(tokens[0], tokens[1].to_int(), args)
