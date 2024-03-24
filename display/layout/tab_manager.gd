extends TabContainer
class_name TabManager

const nine_grid_scene: PackedScene = preload("res://display/layout/nine_grid/nine_grid.tscn")

func _ready() -> void:
	Config.config_update.connect(_config_update)
	if Config.exists:
		_config_update()

func _config_update() -> void:
	for child in get_children():
		child.queue_free()
	var windows: Dictionary = Config.config["windows"]
	for w in windows:
		var window: Dictionary = windows[w]
		match window["layout"]:
			"9-grid":
				var nine_grid: NineGrid = nine_grid_scene.instantiate()
				add_child(nine_grid)
				nine_grid.setup(window)
			_:
				pass
