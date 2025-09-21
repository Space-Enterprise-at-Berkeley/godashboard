# An example of a simulating a 3D card with a 2D TextureRect
# using the Faux 3D Perspective shader by CodeVogel (https://github.com/codevogel/faux-3d-perspective-shader-godot)
@tool
extends SubViewportContainer
class_name Card

@export var front_art: Texture2D = preload("uid://cksqtemkbl2pj"):
	set(value):
		front_art = value
		_refresh()
@export var back_art: Texture2D = preload("uid://cksqtemkbl2pj"):
	set(value):
		back_art = value
		_refresh()
@export var cull_backface: bool = false

@onready var art_texture_rect: TextureRect = $SubViewport/ArtTextureRect
@onready var card_contents: Control = $SubViewport/CardContents

@export_range(1, 120, 1) var simulated_camera_fov: float = 60:
	set(value):
		simulated_camera_fov = value
		_refresh()
@export_range(-360, 360, 1) var rotation_y: float = 0.0:
	set(value):
		rotation_y = value
		_refresh()
@export_range(-360, 360, 1) var rotation_x: float = 0.0:
	set(value):
		rotation_x = value
		_refresh()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not front_art:
		warnings.append("Front art texture is not assigned.")
	if cull_backface:
		if back_art:
			warnings.append(
				"Back art texture will not be visible because backface culling is enabled."
			)
	elif not back_art:
		warnings.append("Back art texture is not assigned.")
	if not (material is ShaderMaterial):
		warnings.append("CardArt requires a ShaderMaterial to function properly.")
	return warnings


func _ready() -> void:
	if not Engine.is_editor_hint():
		_refresh()


func _refresh() -> void:
	if not (material is ShaderMaterial):
		return
	if not card_contents or not art_texture_rect:
		return
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("rot_y_deg", rotation_y)
	shader_material.set_shader_parameter("rot_x_deg", rotation_x)
	shader_material.set_shader_parameter("cull_backface", cull_backface)
	shader_material.set_shader_parameter("fov", simulated_camera_fov)
	_refresh_texture()


func _refresh_texture() -> void:
	if not front_art or not back_art:
		return

	var rot_x_deg : float = wrapf(rotation_x, 0, 360)
	var rot_y_deg : float = wrapf(rotation_y, 0, 360)
	var front_facing_over_x : float = rot_x_deg < 90 or rot_x_deg > 270
	var front_facing_over_y : float = rot_y_deg < 90 or rot_y_deg > 270
	var use_front : float = front_facing_over_y == front_facing_over_x
	card_contents.visible = use_front
	art_texture_rect.texture = front_art if use_front else back_art
	material.set_shader_parameter("use_front", use_front)
