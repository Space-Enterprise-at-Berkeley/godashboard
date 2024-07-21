extends Control
class_name BaseSquare

signal swap(a: int, b: int)

@onready var drag_handle: SquareDragHandle = $DragHandle

func _ready() -> void:
	drag_handle.swap.connect(_handle_swap)

func set_slot(slot: int) -> void:
	drag_handle.slot = slot

func set_square(square: Control) -> void:
	add_child(square)
	drag_handle.move_to_front()

func _handle_swap(a: int, b: int) -> void:
	swap.emit(a, b)
