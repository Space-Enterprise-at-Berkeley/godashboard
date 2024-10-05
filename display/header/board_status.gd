extends PanelContainer
class_name BoardStatus

@export var board: String = ""

@onready var kbps_label: Label = $MarginContainer/Label
@onready var kbpsField: String = board + "Kbps"
@onready var connectedField: String = board + "Connected"
@onready var text: String = board.to_upper() + " - %d"

func _ready() -> void:
	Databus.update.connect(_handle_packet)

func setup(b: String) -> void:
	board = b
	kbpsField = board + "Kbps"
	connectedField = board + "Connected"
	text = board.to_upper() + " - %d"
	update_kbps(0)
	if Databus.boards_connected[b]:
		theme_type_variation = "BoardStatusConnected"

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	if fields.has(kbpsField):
		update_kbps(fields[kbpsField])
	if fields.has(connectedField):
		theme_type_variation = "BoardStatusConnected" if fields[connectedField] else "BoardStatusDisconnected"

func update_kbps(value: float) -> void:
	kbps_label.text = text %int(value)
