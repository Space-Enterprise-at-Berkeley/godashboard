extends Control
class_name OrientationSquare

@onready var rocket: Node3D = $PanelContainer/MarginContainer/SubViewportContainer/SubViewport/Rocket

var qwField: String = ""
var qxField: String = ""
var qyField: String = ""
var qzField: String = ""

var lastQw: float = 0.0
var lastQx: float = 0.0
var lastQy: float = 0.0

var lastRotation: Vector3 = Vector3.UP

func _ready() -> void:
	Databus.update.connect(_handle_packet)

func setup(config: Dictionary) -> void:
	qwField = config["qw"]
	Databus.register_field(qwField)
	qxField = config["qx"]
	Databus.register_field(qxField)
	qyField = config["qy"]
	Databus.register_field(qyField)
	qzField = config["qz"]
	Databus.register_field(qzField)

func update_rotation(lastQz: float) -> void:
	var newRotation: Vector3 = Quaternion(lastQw, lastQx, lastQy, lastQz).normalized().get_euler()
	rocket.rotation = newRotation

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	if fields.has(qwField):
		lastQw = fields[qwField]
	if fields.has(qxField):
		lastQx = fields[qxField]
	if fields.has(qyField):
		lastQy = fields[qyField]
	if fields.has(qzField):
		update_rotation(fields[qzField])
