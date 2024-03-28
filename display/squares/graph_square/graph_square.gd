extends Control
class_name GraphSquare

@onready var header: HFlowContainer = $VBoxContainer/Header
@onready var graph_rects: Control = $VBoxContainer/GraphRects

const graph_header_scene: PackedScene = preload("res://display/squares/graph_square/graph_header.tscn")
const graph_rect_scene: PackedScene = preload("res://display/squares/graph_square/graph_rect.tscn")

const POINT_COUNT: int = 2000
const TIME_WIDTH: int = 30000

var field_names: Array[String] = []
var graphs: Dictionary
var points: Dictionary
var mapped_points: Dictionary
var point_indeces: Dictionary
var colors: Dictionary
var start_time: int

func _ready() -> void:
	start_time = Databus.get_current_time()
	Databus.update.connect(_handle_packet)

func _process(delta: float) -> void:
	var y_min: float = INF
	var y_max: float = -INF
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
	var y_height: float = y_max - y_min
	var time: int = Databus.get_current_time() - start_time
	var time_min: int = time - TIME_WIDTH
	
	for field in field_names:
		var unmapped: PackedVector2Array = points[field]
		var mapped: PackedVector2Array = mapped_points[field]
		var start_index: int = point_indeces[field]
		for i in POINT_COUNT:
			var unmapped_point: Vector2 = unmapped[(i + start_index) % POINT_COUNT]
			mapped[i] = Vector2((unmapped_point.x - time_min) / TIME_WIDTH, 1.0 - ((unmapped_point.y - y_min) / y_height))
		var shader: ShaderMaterial = graphs[field].material as ShaderMaterial
		shader.set_shader_parameter("points", mapped)
		shader.set_shader_parameter("max_y", y_max)
		shader.set_shader_parameter("min_y", y_min)
		shader.set_shader_parameter("timestamp", float(time))

func setup(config: Dictionary) -> void:
	for child in graph_rects.get_children():
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
		var graph: ColorRect = graph_rect_scene.instantiate()
		graphs[f] = graph
		graph_rects.add_child(graph)
		(graph.material as ShaderMaterial).set_shader_parameter("color", color)
		mapped_points[f] = PackedVector2Array()
		mapped_points[f].resize(POINT_COUNT)

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	for f in fields:
		if field_names.has(f):
			points[f][point_indeces[f]] = Vector2(float(timestamp - start_time), fields[f])
			point_indeces[f] = (point_indeces[f] + 1) % POINT_COUNT
