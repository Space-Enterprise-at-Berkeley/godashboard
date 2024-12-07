extends GridContainer
class_name NineGrid

const base_square_scene: PackedScene = preload("res://display/squares/base_square/base_square.tscn")
const four_button_square_scene: PackedScene = preload("res://display/squares/four_button_square/four_button_square.tscn")
const graph_square_scene: PackedScene = preload("res://display/squares/graph_square/graph_square.tscn")
const six_value_square_scene: PackedScene = preload("res://display/squares/six_value_square/six_value_square.tscn")
const logs_square_scene: PackedScene = preload("res://display/squares/logs_square/logs_square.tscn")
const camera_square_scene: PackedScene = preload("res://display/squares/camera_square/camera_square.tscn")
const launch_button_square_scene: PackedScene = preload("res://display/squares/launch_button_square/launch_button_square.tscn")
const orientation_square_scene: PackedScene = preload("res://display/squares/orientation_square/orientation_square.tscn")
const empty_square_scene: PackedScene = preload("res://display/squares/empty_square.gd/empty_square.tscn")

func setup(config: Dictionary) -> void:
	columns = ceil(sqrt(len(config["slots"])))
	name = config["name"]
	for slot: Dictionary in config["slots"]:
		var base_square: BaseSquare = base_square_scene.instantiate()
		add_child(base_square)
		base_square.set_slot(get_children().size() - 1)
		base_square.swap.connect(_handle_swap)
		match slot["type"]:
			"six-square":
				var six_value_square: SixValueSquare = six_value_square_scene.instantiate()
				base_square.set_square(six_value_square)
				six_value_square.setup(slot)
			"graph":
				var graph_square: GraphSquare = graph_square_scene.instantiate()
				base_square.set_square(graph_square)
				graph_square.setup(slot)
			"four-button":
				var four_button_square: FourButtonSquare = four_button_square_scene.instantiate()
				base_square.set_square(four_button_square)
				four_button_square.setup(slot)
			"logs":
				var logs_square: LogsSquare = logs_square_scene.instantiate()
				base_square.set_square(logs_square)
			"camera":
				var camera_square: CameraSquare = camera_square_scene.instantiate()
				base_square.set_square(camera_square)
				camera_square.setup(slot)
			"launch":
				var launch_button_square: LaunchButtonSquare = launch_button_square_scene.instantiate()
				base_square.set_square(launch_button_square)
			"orientation":
				var orientation_square: OrientationSquare = orientation_square_scene.instantiate()
				base_square.set_square(orientation_square)
				orientation_square.setup(slot)
			"empty":
				var empty_square: Control = empty_square_scene.instantiate()
				base_square.set_square(empty_square)
			_:
				pass

func _handle_swap(a: int, b: int) -> void:
	var child_a: BaseSquare = get_child(a)
	var child_b: BaseSquare = get_child(b)
	move_child(child_a, b)
	move_child(child_b, a)
	child_a.set_slot
