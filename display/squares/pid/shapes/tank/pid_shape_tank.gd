extends Node2D
class_name PidShapeTank

@onready var color_rect: ColorRect = $ColorRect

const TOP_OFFSET: Vector2 = Vector2(0, -40)
const BOTTOM_OFFSET: Vector2 = Vector2(0, 40)

func setup(config: Dictionary, positions: Dictionary, get_pos: Callable) -> void:
	var pos: Vector2 = get_pos.call(config["pos"])
	var node_name: String = config["name"]
	position = pos
	positions[node_name] = pos
	positions["%s/top" % node_name] = pos + TOP_OFFSET
	positions["%s/bottom" % node_name] = pos + BOTTOM_OFFSET
	var shader: ShaderMaterial = color_rect.material
	shader.set_shader_parameter("fill_color", Util.parse_color(config["color"]))
