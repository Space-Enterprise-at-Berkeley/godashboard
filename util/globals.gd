extends Node

var heartbeat_timer: Timer
var theme: Theme

func _ready() -> void:
	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 1.0
	heartbeat_timer.autostart = true
	add_child(heartbeat_timer)
	heartbeat_timer.timeout.connect(_heartbeat)
	heartbeat_timer.start()
	Databus.update.connect(_handle_packet)

func _heartbeat() -> void:
	Databus.validate_and_send("bcast", "Heartbeat", {
		"packetSpecVersion": Config.config["protoConfig"]["version"]
	}, true)
	Databus.send_packet("bcast", 249, [])

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	if fields.has("abortReason"):
		Logger.warn("Abort reason: %s" % fields["abortReason"])
