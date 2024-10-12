extends Control
class_name SixValueSquare

@onready var grid: GridContainer = $GridContainer

const six_value_square_field_scene: PackedScene = preload("res://display/squares/six_value_square/six_value_square_field.tscn")

func setup(config: Dictionary) -> void:
	for field: Variant in config["values"]:
		var six_value_square_field: SixValueSquareField = six_value_square_field_scene.instantiate()
		grid.add_child(six_value_square_field)
		if field == null:
			six_value_square_field.setup({}, true)
		else:
			six_value_square_field.setup(field, false)
