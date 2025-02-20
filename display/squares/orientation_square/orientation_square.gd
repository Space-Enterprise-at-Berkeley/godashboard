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

func setup(config: Dictionary) -> void:
	qwField = config["qw"]
	Databus.register_callback(qwField, get_window(), _handle_packet_w)
	qxField = config["qx"]
	Databus.register_callback(qxField, get_window(), _handle_packet_x)
	qyField = config["qy"]
	Databus.register_callback(qyField, get_window(), _handle_packet_y)
	qzField = config["qz"]
	Databus.register_callback(qzField, get_window(), _handle_packet_z)

func update_rotation(lastQz: float) -> void:
	var newRotation: Vector3 = Quaternion(lastQw, lastQx, lastQy, lastQz).normalized().get_euler()
	rocket.rotation = newRotation

func _handle_packet_w(value: float, timestamp: int) -> void:
	lastQw = value

func _handle_packet_x(value: float, timestamp: int) -> void:
	lastQx = value

func _handle_packet_y(value: float, timestamp: int) -> void:
	lastQy = value

func _handle_packet_z(value: float, timestamp: int) -> void:
	update_rotation(value)
