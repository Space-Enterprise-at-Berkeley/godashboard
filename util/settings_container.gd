@tool
extends Container
class_name SettingsContainer

func _notification(what: int) -> void:
	print(what)
	if what == NOTIFICATION_SORT_CHILDREN:
		var children: Array[Node] = get_children()
		fit_child_in_rect(children[0], Rect2(Vector2(), size))
		fit_child_in_rect(children[1], Rect2(Vector2(), size))
