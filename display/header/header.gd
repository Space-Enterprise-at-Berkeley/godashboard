extends HBoxContainer
class_name Header

const board_status_scene: PackedScene = preload("res://display/header/board_status.tscn")

func _ready() -> void:
	Config.config_update.connect(_config_update)
	if Config.exists:
		_config_update()

func _config_update() -> void:
	for child in get_children():
		child.queue_free()
	for board in Config.config["boards"]:
		var board_status: BoardStatus = board_status_scene.instantiate()
		add_child(board_status)
		board_status.setup(board)
