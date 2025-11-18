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
	Databus.register_callback("abortReason", null, _handle_abort_packet)

func _heartbeat() -> void:
	Databus.validate_and_send("bcast", "Heartbeat", {
		"packetSpecVersion": Config.config["protoConfig"]["version"]
	}, true)

func _handle_abort_packet(value: Variant, timestamp: int) -> void:
	var abort_name: String = "";
	var abort_enums: Dictionary = Config.config["reverse_enum_lookup"]["AbortCode"];
	if abort_enums.has(value):
		abort_name = abort_enums[value];
	else:
		abort_name = "[UNKNOWN ABORTCODE]";
	GoLogger.warn("Abort code %s: %s" % [value, abort_name]);
