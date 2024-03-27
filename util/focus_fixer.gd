extends Control

func _ready():
	get_tree().node_added.connect(_node_added)

func _node_added(node: Node):
	if node is Control:
		node.focus_mode = Control.FOCUS_CLICK
	if node is Button:
		node.focus_mode = Control.FOCUS_NONE
