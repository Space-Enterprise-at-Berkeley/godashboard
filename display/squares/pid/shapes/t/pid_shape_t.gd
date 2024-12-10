extends Node2D
class_name PidShapeT

@onready var sprite_2d: Sprite2D = $Sprite2D

const plus_texture: Texture = preload("res://display/squares/pid/shapes/t/pid_shape_plus.png")

const NORTH_OFFSET: Vector2 = Vector2(0, -10)
const EAST_OFFSET: Vector2 = Vector2(10, 0)
const SOUTH_OFFSET: Vector2 = Vector2(0, 10)
const WEST_OFFSET: Vector2 = Vector2(-10, 0)

func setup(config: Dictionary, positions: Dictionary, get_pos: Callable) -> void:
	var pos: Vector2 = get_pos.call(config["pos"])
	var node_name: String = config["name"]
	match config["direction"]:
		"north":
			rotation_degrees = 0
		"east":
			rotation_degrees = 90
		"south":
			rotation_degrees = 180
		"west":
			rotation_degrees = 270
		"plus":	
			sprite_2d.texture = plus_texture
	position = pos
	positions[node_name] = pos
	positions["%s/north" % node_name] = pos + NORTH_OFFSET
	positions["%s/east" % node_name] = pos + EAST_OFFSET
	positions["%s/south" % node_name] = pos + SOUTH_OFFSET
	positions["%s/west" % node_name] = pos + WEST_OFFSET
