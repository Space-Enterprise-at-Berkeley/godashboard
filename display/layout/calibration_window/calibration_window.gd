extends GridContainer
class_name CalibrationWindow

const calibration_entry_scene: PackedScene = preload("res://display/layout/calibration_window/calibration_entry.tscn")

func setup(config: Dictionary) -> void:
	name = config["name"]
	columns = config["columns"]
	var channels: Dictionary = Config.config["channel_mappings"][config["board"]]
	for i: int in config["channels"]:
		var entry: CalibrationEntry = calibration_entry_scene.instantiate()
		add_child(entry)
		var field: String = ""
		var channel_name: String = "Unmapped (%d)" % i
		if channels.has(i):
			var channel: String = channels[i]
			channel_name = "%s (%d)" % [channel, i]
			var segments: PackedStringArray = config["fieldUnmapped"].split(".", true, 1)
			field = "%s.%s" % [segments[0].substr(0, 2), segments[1]]
			field = field.replace("#", channel)
		else:
			field = config["fieldUnmapped"].replace("#", str(i))
		if Config.config["influxMap"].has(field):
			field = Config.config["influxMap"][field]
		entry.setup({
			"board": config["board"],
			"channel": i,
			"name": channel_name,
			"units": config["units"],
			"color": config["color"],
			"firstPoint": config["firstPoint"],
			"secondPoint": config["secondPoint"],
			"reset": config["reset"],
			"field": field
		})
