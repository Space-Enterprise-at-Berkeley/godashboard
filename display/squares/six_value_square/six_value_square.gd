extends Control
class_name SixValueSquare

@onready var grid: GridContainer = $GridContainer

const six_value_square_field_scene: PackedScene = preload("res://display/squares/six_value_square/six_value_square_field.tscn")

func setup(config: Dictionary) -> void:
	for field in config["values"]:
		var six_value_square_field: SixValueSquareField = six_value_square_field_scene.instantiate()
		grid.add_child(six_value_square_field)
		six_value_square_field.setup(field)
