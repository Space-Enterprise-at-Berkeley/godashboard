extends HBoxContainer
class_name GraphHeader

@onready var color_rect = $ColorRect
@onready var text = $Label

var field: String = ""
var units: String = ""
var color: Array[int] = [255, 255, 255]
var name_text: String = ""

func _ready() -> void:
	Databus.update.connect(_handle_packet)

func setup(config: Dictionary) -> void:
	field = config["field"]
	units = config["units"]
	name_text = config["name"]
	color_rect.color = Color(config["color"][0] / 255.0, config["color"][1] / 255.0, config["color"][2] / 255.0)
	text.text = "%s (%s %s)" %[config["name"], "0.0", units]

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	if fields.has(field):
		update_field(fields[field])

func update_field(value: float) -> void:
	text.text = "%s (%s %s)" %[name_text, str(value).pad_decimals(1), units]
