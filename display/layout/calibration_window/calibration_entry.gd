extends PanelContainer
class_name CalibrationEntry

@onready var updating_field: SixValueSquareField = $HBoxContainer/MarginContainer/VBoxContainer/UpdatingField
@onready var graph_square: GraphSquare = $HBoxContainer/GraphSquare

func setup(config: Dictionary) -> void:
	updating_field.setup({
		"field": "",
		"name": config["name"],
		"units": config["units"]
	}, false)
