extends HBoxContainer
class_name GraphHeader

@onready var color_rect: ColorRect = $ColorRect
@onready var text: Label = $Label

var field: String = ""
var units: String = ""
var color: Array[int] = [255, 255, 255]
var name_text: String = ""
var last_timestamp: int = 0

func setup(config: Dictionary) -> void:
	field = config["field"]
	units = config["units"]
	name_text = config["name"]
	color_rect.color = Util.parse_color(config["color"])
	text.text = "%s (%s %s)" %[config["name"], "0.0", units]
	Databus.register_callback(field, get_window(), _handle_packet)

func _handle_packet(value: Variant, timestamp: int) -> void:
	if abs(timestamp - last_timestamp) <= 100:
		return
	update_field(value)
	last_timestamp = timestamp

func update_field(value: float) -> void:
	text.text = "%s (%s %s)" %[name_text, str(value).pad_decimals(1), units]
