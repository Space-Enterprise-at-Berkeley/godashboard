extends VBoxContainer
class_name SixValueSquareField

@onready var name_label: Label = $Name
@onready var value_label: Label = $Value

var field: String = ""
var units: String = ""
var name_text: String = ""
var last_timestamp: int = 0
var mode: String = "value"    # value or counter
var count: int = 0
var last_value: Variant = null

func setup(config: Dictionary, is_null: bool) -> void:
	if is_null:
		name_label.hide()
		value_label.hide()
		return
	field = config["field"]
	units = config["units"]
	name_text = name
	name_label.text = config["name"]
	mode = config.get("mode", "value")
	if mode == "counter":
		Databus.register_callback(field, get_window(), _handle_packet_counter)
		update_field(0)
	else:
		Databus.register_callback(field, get_window(), _handle_packet)
		update_field(0.0)

func _handle_packet(value: Variant, timestamp: int) -> void:
	if abs(timestamp - last_timestamp) <= 100:
		return
	update_field(value)
	last_timestamp = timestamp

func _handle_packet_counter(value: Variant, timestamp: int) -> void:
	if last_value == value:
		return
	count = count + 1
	update_field(count, 0)
	last_value = value

func update_field(value: float, decimals: int = 1) -> void:
	value_label.text = str(value).pad_decimals(decimals) + " " + units
