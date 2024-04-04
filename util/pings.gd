extends Node

var timers: Dictionary = {}

func add_ping(id: String, f: Callable, delay: float) -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = delay / 1000.0
	add_child(timer)
	timers[id] = timer
	timer.timeout.connect(f)
	timer.start()

func remove_ping(id: String) -> void:
	if not timers.has(id):
		return
	timers[id].queue_free()
	timers.erase(id)
