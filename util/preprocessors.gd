extends Node

func get_preprocessor(field: String) -> Callable:
	var preprocessor_data: String = field.split("@")[1]
	return func () -> void: null
