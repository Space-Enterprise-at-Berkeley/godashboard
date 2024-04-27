extends TabContainer
class_name TabManager

const nine_grid_scene: PackedScene = preload("res://display/layout/nine_grid/nine_grid.tscn")
const packet_simulator_scene: PackedScene = preload("res://display/layout/packet_simulator/packet_simulator.tscn")

func _ready() -> void:
	pass

func add_tab(tab: String) -> void:
	var windows: Dictionary = Config.config["windows"]
	var window: Dictionary = windows[tab]
	match window["layout"]:
		"9-grid":
			var nine_grid: NineGrid = nine_grid_scene.instantiate()
			add_child(nine_grid)
			nine_grid.setup(window)
		"packet-simulator":
			var packet_simulator: PacketSimulator = packet_simulator_scene.instantiate()
			add_child(packet_simulator)
			packet_simulator.setup(window)
		_:
			pass
