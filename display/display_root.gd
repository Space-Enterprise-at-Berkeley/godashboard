extends Node
class_name DisplayRoot

@onready var theme_node: Control = $CanvasLayer/Theme

func _ready() -> void:
	Globals.theme = theme_node.theme
