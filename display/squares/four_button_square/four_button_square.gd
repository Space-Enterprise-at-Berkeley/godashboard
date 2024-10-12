extends Control
class_name FourButtonSquare

@onready var grid_container: GridContainer = $GridContainer

const generic_button_scene: PackedScene = preload("res://display/squares/four_button_square/generic_button.tscn")

func setup(config: Dictionary) -> void:
	for button_config: Variant in config["buttons"]:
		var button: GenericButton = generic_button_scene.instantiate()
		grid_container.add_child(button)
		if button_config == null:
			button.setup({}, true)
		else:
			button.setup(button_config, false)

func _get_drag_data(at_position: Vector2) -> Variant:
	print(1)
	return null
