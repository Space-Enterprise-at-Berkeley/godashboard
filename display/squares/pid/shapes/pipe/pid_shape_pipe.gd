extends Node2D
class_name PidShapePipe

@onready var line_2d: Line2D = $Line2D

func setup(config: Dictionary, positions: Dictionary, get_pos: Callable) -> void:
	for point: Variant in config["points"]:
		var p: Vector2 = get_pos.call(point)
		line_2d.add_point(p)
