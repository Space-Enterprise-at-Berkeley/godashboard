extends GridContainer
class_name NineGrid

const six_value_square_scene: PackedScene = preload("res://display/squares/six_value_square/six_value_square.tscn")
const graph_square_scene: PackedScene = preload("res://display/squares/graph_square/graph_square.tscn")

func setup(config: Dictionary) -> void:
	name = config["name"]
	for slot in config["slots"]:
		match slot["type"]:
			"six-square":
				var six_value_square: SixValueSquare = six_value_square_scene.instantiate()
				add_child(six_value_square)
				six_value_square.setup(slot)
			"graph":
				var graph_square: GraphSquare = graph_square_scene.instantiate()
				add_child(graph_square)
				graph_square.setup(slot)
			_:
				pass
