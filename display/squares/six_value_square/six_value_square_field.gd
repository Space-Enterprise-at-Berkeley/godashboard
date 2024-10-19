extends VBoxContainer
class_name SixValueSquareField

@onready var name_label: Label = $Name
@onready var value_label: Label = $Value

var field: String = ""
var units: String = ""
var name_text: String = ""

func _ready() -> void:
	Databus.update.connect(_handle_packet)

func setup(config: Dictionary, is_null: bool) -> void:
	if is_null:
		name_label.hide()
		value_label.hide()
		return
	field = config["field"]
	if field.split("@")[0] not in Config.config["influxMap"].values():
		print("Field %s not in Influx map. This data may not work" % field)
	Databus.register_field(field)
	units = config["units"]
	name_text = name
	name_label.text = config["name"]

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	if fields.has(field):
		update_field(fields[field])

func update_field(value: float) -> void:
	value_label.text = str(value).pad_decimals(1) + " " + units
