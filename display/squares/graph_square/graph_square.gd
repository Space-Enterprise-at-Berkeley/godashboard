extends Control
class_name GraphSquare

@onready var header: HFlowContainer = $VBoxContainer/Header
@onready var viewport: SubViewport = $VBoxContainer/SubViewportContainer/SubViewport
@onready var color_rect: ColorRect = $VBoxContainer/ColorRect

const graph_header_scene: PackedScene = preload("res://display/squares/graph_square/graph_header.tscn")

const POINT_COUNT: int = 5
const TIME_MODULO: int = 10000000

var field_names: Array[String] = []
var points: Dictionary
var point_indeces: Dictionary
var colors: Dictionary

func _ready() -> void:
	Databus.update.connect(_handle_packet)

func _process(delta: float) -> void:
	var y_min: float = INF
	var y_max: float = -INF
	var x_max: int = Databus.get_current_time()
	var x_min: int = x_max - 30000
	for field in field_names:
		for point in points[field]:
			if point.x >= 0:
				if point.y < y_min:
					y_min = point.y
				if point.y > y_max:
					y_max = point.y
	if not is_finite(y_min) or not is_finite(y_max):
		y_min = 0
		y_max = 0
	var y_height_initial: float = y_max - y_min
	y_min -= maxf(0.1, 0.05 * y_height_initial)
	y_max += maxf(0.1, 0.05 * y_height_initial)
	
	var shader: ShaderMaterial = color_rect.material as ShaderMaterial
	shader.set_shader_parameter("points", points[points.keys()[0]])
	shader.set_shader_parameter("max_y", y_max)
	shader.set_shader_parameter("min_y", y_min)
	shader.set_shader_parameter("timestamp", float(Databus.get_current_time() % TIME_MODULO))
	shader.set_shader_parameter("start_index", point_indeces[points.keys()[0]])

func setup(config: Dictionary) -> void:
	for child in viewport.get_children():
		child.queue_free()
	for field in config["values"]:
		var graph_header: GraphHeader = graph_header_scene.instantiate()
		header.add_child(graph_header)
		graph_header.setup(field)
		var f: String = field["field"]
		field_names.append(f)
		points[f] = PackedVector2Array()
		points[f].resize(POINT_COUNT)
		points[f].fill(Vector2(0, -1))
		var color: Color = Color(field["color"][0] / 255.0, field["color"][1] / 255.0, field["color"][2] / 255.0)
		colors[f] = color
		point_indeces[f] = 0

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	for f in fields:
		if field_names.has(f):
			points[f][point_indeces[f]] = Vector2(float(timestamp % TIME_MODULO), fields[f])
			point_indeces[f] = (point_indeces[f] + 1) % POINT_COUNT
