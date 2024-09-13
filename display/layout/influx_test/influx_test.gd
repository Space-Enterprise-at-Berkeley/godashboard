extends VBoxContainer
class_name InfluxTest

@onready var start: Button = $Start
@onready var bitrate: TextEdit = $Bitrate
@onready var number_fields: TextEdit = $NumberFields
@onready var timer: Timer = $Timer

const FREQUENCY: float = 20.0

var current_bitrate: int = 0
var current_number_fields: int = 1

func _ready() -> void:
	start.pressed.connect(_update_bitrate)
	timer.timeout.connect(_send_data)

func setup(config: Dictionary) -> void:
	name = config["name"]

func _update_bitrate() -> void:
	current_bitrate = int(bitrate.text)
	current_number_fields = int(number_fields.text)

func _send_data() -> void:
	var rounds: int = roundi(float(current_bitrate) / float(current_number_fields) / FREQUENCY)
	var update: Dictionary = {}
	for f in current_number_fields:
		update["influx_test.test_%d" % f] = PI
	for r in rounds:
		Databus.send_update(update, Databus.get_current_time())
