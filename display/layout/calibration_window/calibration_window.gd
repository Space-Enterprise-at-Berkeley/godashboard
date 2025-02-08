extends GridContainer
class_name CalibrationWindow

const calibration_entry_scene: PackedScene = preload("res://display/layout/calibration_window/calibration_entry.tscn")

func setup(config: Dictionary) -> void:
	for slot: Dictionary in config["slots"]:
		var entry: CalibrationEntry = calibration_entry_scene.instantiate()
		add_child(entry)
		entry.setup(slot)
