extends Node

var heartbeat_timer: Timer
var theme: Theme
var heartbeat_enabled: bool = false

func _ready() -> void:
	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 1.0
	heartbeat_timer.autostart = true
	add_child(heartbeat_timer)
	heartbeat_timer.timeout.connect(_heartbeat)
	heartbeat_timer.start()

func _heartbeat() -> void:
	Databus.send_packet("bcast", 249, [Databus.make_uint8(1 if heartbeat_enabled else 0)])
