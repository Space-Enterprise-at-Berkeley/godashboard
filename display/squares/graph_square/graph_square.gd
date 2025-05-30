extends Control
class_name GraphSquare

@onready var header: HFlowContainer = $VBoxContainer/Header
@onready var viewport: SubViewport = $VBoxContainer/Control/SubViewportContainer/SubViewport
@onready var upper_label: Label = $VBoxContainer/Control/UpperLabelMargin/UpperLabel
@onready var lower_label: Label = $VBoxContainer/Control/LowerLabelMargin/LowerLabel
@onready var filter_timer: Timer = $FilterTimer

static var graph_count: int = 0

const graph_header_scene: PackedScene = preload("res://display/squares/graph_square/graph_header.tscn")

var field_names: Array[String] = []
var points: Dictionary = {}
var colors: Dictionary = {}
var lines: Dictionary = {}
var last_timestamps: Dictionary = {}
var graph_id: int = 0

func _ready() -> void:
	graph_id = graph_count
	graph_count += 1
	filter_timer.timeout.connect(_filter_points)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var y_min: float = INF
	var y_max: float = -INF
	var x_max: int = Databus.get_current_time()
	var x_min: int = x_max - 30000
	for field in field_names:
		for point: Array in points[field]:
			if point[0] < y_min:
				y_min = point[0]
			if point[0] > y_max:
				y_max = point[0]
	if not is_finite(y_min) or not is_finite(y_max):
		y_min = 0
		y_max = 0
	var y_height_initial: float = y_max - y_min
	y_min -= maxf(0.1, 0.05 * y_height_initial)
	y_max += maxf(0.1, 0.05 * y_height_initial)
	upper_label.text = "%.2f" % y_max
	lower_label.text = "%.2f" % y_min
	var y_height: float = y_max - y_min
	for field in field_names:
		var vector_points: PackedVector2Array = PackedVector2Array()
		for point: Array in points[field]:
			var x_pos: float = viewport.size.x * (point[1] - x_min) / 30000.0
			var y_pos: float = viewport.size.y * (1 - ((point[0] - y_min) / y_height))
			vector_points.append(Vector2(x_pos, y_pos))
		lines[field].points = vector_points

func _filter_points() -> void:
	var x_max: int = Databus.get_current_time()
	var x_min: int = x_max - 30000
	for field in field_names:
		points[field] = points[field].filter(func (v: Array) -> bool: return v[1] >= x_min)

func setup(config: Dictionary) -> void:
	for child in viewport.get_children():
		child.queue_free()
	for field: Dictionary in config["values"]:
		var graph_header: GraphHeader = graph_header_scene.instantiate()
		header.add_child(graph_header)
		graph_header.setup(field)
		var f: String = field["field"]
		field_names.append(f)
		Databus.register_callback(f, get_window(), _handle_packet.bind(f))
		points[f] = []
		var color: Color = Util.parse_color(field["color"])
		colors[f] = color
		var line: Line2D = Line2D.new()
		line.default_color = color
		line.width = 2
		viewport.add_child(line)
		lines[f] = line
		last_timestamps[f] = 0

func _handle_packet(value: Variant, timestamp: int, f: String) -> void:
	if abs(timestamp - last_timestamps[f]) > 100:
		points[f].append([value, timestamp])
		last_timestamps[f] = timestamp
