extends Control
class_name SquareDragHandle

signal swap(a: int, b: int)

var slot: int

func _get_drag_data(at_position: Vector2) -> Variant:
	return slot

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data != slot:
		swap.emit(data, slot)
