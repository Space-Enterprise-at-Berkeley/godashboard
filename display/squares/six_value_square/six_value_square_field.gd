extends VBoxContainer
class_name SixValueSquareField

@onready var name_label: Label = $Name
@onready var value_label: Label = $Value

var field: String = ""
var units: String = ""
var name_text: String = ""
var last_timestamp: int = 0

func setup(config: Dictionary, is_null: bool) -> void:
	if is_null:
		name_label.hide()
		value_label.hide()
		return
	field = config["field"]
	units = config["units"]
	name_text = name
	name_label.text = config["name"]
	Databus.register_callback(field, get_window(), _handle_packet)

func _handle_packet(value: Variant, timestamp: int) -> void:
	if abs(timestamp - last_timestamp) <= 100:
		return
	update_field(value)
	last_timestamp = timestamp

func update_field(value: float) -> void:
	value_label.text = str(value).pad_decimals(1) + " " + units
