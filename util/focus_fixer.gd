extends Control

func _ready() -> void:
	get_tree().node_added.connect(_node_added)

func _node_added(node: Node) -> void:
	if node is Control:
		node.focus_mode = Control.FOCUS_CLICK
	if node is Button:
		node.focus_mode = Control.FOCUS_NONE
