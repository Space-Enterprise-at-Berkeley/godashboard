extends Control
class_name PidSquare

@onready var root: Node2D = $HBoxContainer/SubViewportContainer/SubViewport/Node2D
@onready var sub_viewport: SubViewport = $HBoxContainer/SubViewportContainer/SubViewport
@onready var background_grid: Sprite2D = $HBoxContainer/SubViewportContainer/SubViewport/Node2D/BackgroundGrid
@onready var pipes: Node2D = $HBoxContainer/SubViewportContainer/SubViewport/Node2D/Pipes
@onready var nodes: Node2D = $HBoxContainer/SubViewportContainer/SubViewport/Node2D/Nodes

const tank_scene = preload("res://display/squares/pid/shapes/tank/pid_shape_tank.tscn")
const t_scene = preload("res://display/squares/pid/shapes/t/pid_shape_t.tscn")
const pipe_scene = preload("res://display/squares/pid/shapes/pipe/pid_shape_pipe.tscn")

const VIEWPORT_WIDTH: float = 1920.0 * 0.9 # Possibly correct
const VIEWPORT_HEIGHT: float = 1080.0 * 0.9 # Definitely not correct

var positions: Dictionary = {}
var start_coord: Vector2 = Vector2.ZERO
var scale_factor: float = 0.0
var debug: bool = false

var tool_none: PidEditorTool = PidEditorTool.new()
var tool_select: PidEditorTool = PidEditorToolSelect.new()
var current_tool: PidEditorTool = tool_none

func _ready() -> void:
	_set_current_tool(tool_select)

func setup(config: Dictionary) -> void:
	if !is_node_ready():
		await ready
	var grid_start: Array = config["gridStart"]
	var grid_end: Array = config["gridEnd"]
	var grid_width: float = grid_end[0] - grid_start[0]
	var grid_height: float = grid_end[1] - grid_start[1]
	if grid_height / grid_width >= VIEWPORT_HEIGHT / VIEWPORT_WIDTH:
		scale_factor = VIEWPORT_HEIGHT / grid_height
		start_coord = Vector2(-(grid_width * scale_factor) / 2.0, -VIEWPORT_HEIGHT / 2.0)
	else:
		scale_factor = VIEWPORT_WIDTH / grid_width
		start_coord = Vector2(-VIEWPORT_WIDTH / 2.0, -(grid_height * scale_factor) / 2.0)
	
	_enable_debug() # Remove this later
	
	background_grid.position = start_coord
	background_grid.scale = Vector2(grid_width * scale_factor / 128.0, grid_height * scale_factor / 128.0)
	var background_material: ShaderMaterial = background_grid.material
	background_material.set_shader_parameter("height", VIEWPORT_HEIGHT)
	background_material.set_shader_parameter("width", VIEWPORT_WIDTH)
	background_material.set_shader_parameter("grid_lines_h", grid_height)
	background_material.set_shader_parameter("grid_lines_w", grid_width)
	
	for node: Dictionary in config["nodes"]:
		match (node["type"]):
			"tank":
				var tank: PidShapeTank = tank_scene.instantiate()
				nodes.add_child(tank)
				tank.setup(node, positions, get_pos)
			"t":
				var t: PidShapeT = t_scene.instantiate()
				nodes.add_child(t)
				t.setup(node, positions, get_pos)
	for pipe: Dictionary in config["pipes"]:
		var pipe_obj: PidShapePipe = pipe_scene.instantiate()
		pipes.add_child(pipe_obj)
		pipe_obj.setup(pipe, positions, get_pos)

func get_pos(pos: Variant) -> Vector2i:
	if typeof(pos) == TYPE_ARRAY:
		return Vector2i(pos[0], pos[1]) * scale_factor + start_coord
	if positions.has(pos):
		return positions[pos]
	return Vector2i.ZERO

func _enable_debug() -> void:
	debug = true
	background_grid.show()

func _disable_debug() -> void:
	debug = false
	background_grid.hide()

func _set_current_tool(tool: PidEditorTool) -> void:
	var different: bool = tool != current_tool
	if different:
		current_tool.on_exit(self)
	current_tool = tool
	if different:
		tool.on_enter(self)
