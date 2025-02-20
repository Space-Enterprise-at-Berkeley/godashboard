extends PanelContainer
class_name BoardStatus

@export var board: String = ""

@onready var kbps_label: Label = $MarginContainer/Label
@onready var kbpsField: String = board + "Kbps"
@onready var connectedField: String = board + "Connected"
@onready var text: String = board.to_upper() + " - %d"

func setup(b: String) -> void:
	board = b
	kbpsField = board + "Kbps"
	connectedField = board + "Connected"
	Databus.register_callback(kbpsField, get_window(), _handle_packet_kbps)
	Databus.register_callback(connectedField, get_window(), _handle_packet_connected)
	text = board.to_upper() + " - %d"
	update_kbps(0)
	if Databus.boards_connected[b]:
		theme_type_variation = "BoardStatusConnected"

func _handle_packet_kbps(value: int, timestamp: int) -> void:
	update_kbps(value)

func _handle_packet_connected(value: bool, timestamp: int) -> void:
	theme_type_variation = "BoardStatusConnected" if value else "BoardStatusDisconnected"

func update_kbps(value: float) -> void:
	kbps_label.text = text %int(value)
