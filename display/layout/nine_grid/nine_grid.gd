extends GridContainer
class_name NineGrid

const four_button_square_scene: PackedScene = preload("res://display/squares/four_button_square/four_button_square.tscn")
const graph_square_scene: PackedScene = preload("res://display/squares/graph_square/graph_square.tscn")
const six_value_square_scene: PackedScene = preload("res://display/squares/six_value_square/six_value_square.tscn")
const logs_square_scene: PackedScene = preload("res://display/squares/logs_square/logs_square.tscn")
const camera_square_scene: PackedScene = preload("res://display/squares/camera_square/camera_square.tscn")

func setup(config: Dictionary) -> void:
	columns = ceil(sqrt(len(config["slots"])))
	name = config["name"]
	for slot: Dictionary in config["slots"]:
		match slot["type"]:
			"six-square":
				var six_value_square: SixValueSquare = six_value_square_scene.instantiate()
				add_child(six_value_square)
				six_value_square.setup(slot)
			"graph":
				var graph_square: GraphSquare = graph_square_scene.instantiate()
				add_child(graph_square)
				graph_square.setup(slot)
			"four-button":
				var four_button_square: FourButtonSquare = four_button_square_scene.instantiate()
				add_child(four_button_square)
				four_button_square.setup(slot)
			"logs":
				var logs_square: LogsSquare = logs_square_scene.instantiate()
				add_child(logs_square)
			"camera":
				var camera_square: CameraSquare = camera_square_scene.instantiate()
				add_child(camera_square)
				camera_square.setup(slot)
			_:
				pass
