extends Node
class_name Launcher

enum SubPropertyType {
	COLOR,
	INT,
}

@export_file var theme_definition_file: String
@export_file var theme_file: String

@onready var theme_node: Control = $CanvasLayer/Theme
@onready var quick_presets: HBoxContainer = $CanvasLayer/Theme/PanelContainer/VBoxContainer/QuickPresets
@onready var windows_list: Node = $Windows

const display_root_scene: PackedScene = preload("res://display/display_root.tscn")
const launcher_quick_config_button_scene: PackedScene = preload("res://display/launcher/launcher_quick_config_button.tscn")

var theme_definition: Variant = {}
var windows: Dictionary = {}

func _ready() -> void:
	var file: FileAccess = FileAccess.open(theme_definition_file, FileAccess.READ)
	var text: String = file.get_as_text()
	theme_definition = Config.parse_config(text)
	theme_node.theme = _generate_theme(theme_file)
	for window: String in windows:
		windows[window].update_theme(theme_node.theme)
	Globals.theme = theme_node.theme
	if Config.exists:
		_config_update()

func _config_update() -> void:
	var presets: Dictionary = Config.config["windowPresets"]
	for button in quick_presets.get_children():
		button.queue_free()
	for quick_preset: String in Config.config["quickWindowPresets"]:
		var quick_preset_button: Button = launcher_quick_config_button_scene.instantiate()
		quick_preset_button.text = presets[quick_preset]["name"]
		quick_preset_button.pressed.connect(_create_window.bind(presets[quick_preset]["name"], presets[quick_preset]["tabs"]))
		quick_preset_button.clip_text = true
		quick_presets.add_child(quick_preset_button)

func _create_window(title: String, tabs: Array) -> void:
	var window: DisplayRoot = display_root_scene.instantiate()
	windows_list.add_child(window)
	window.title = title
	for tab: String in tabs:
		window.add_tab(tab)
	window.update_theme(theme_node.theme)
	windows[window.name] = window
	window.close_requested.connect(_close_window.bind(window.name))

func _close_window(window: String) -> void:
	var w: Window = windows[window]
	w.queue_free()
	windows.erase(window)
	if windows.size() == 0:
		get_tree().quit()

func _generate_theme(filepath: String) -> Theme:
	var theme: Theme = Theme.new()
	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	var text: String = file.get_as_text()
	var theme_json: Variant = Config.parse_config(text)
	for theme_type: String in theme_definition:
		for property: String in theme_definition[theme_type]:
			if property == "@":
				theme.add_type(theme_type)
				theme.set_type_variation(theme_type, theme_definition[theme_type][property])
			var value_type: String = theme_definition[theme_type][property][0]
			var value: Variant = theme_definition[theme_type][property][1]
			_parse_and_add_value(theme, theme_json, theme_type, property, value_type, value)
	return theme

func _find_theme_property(theme_json: Variant, path: String, default: Variant) -> Variant:
	var result: Variant = default
	var split_name: PackedStringArray = path.split(":")
	var parsed_path: PackedStringArray = split_name[0].split("/")
	var target: String = split_name[1]
	for segment in parsed_path:
		if not theme_json.has(segment):
			return result
		theme_json = theme_json[segment]
		if theme_json.has(target):
			result = theme_json[target]
	return result

func _parse_and_add_value(theme: Theme, theme_json: Variant, theme_type: String, property: String, value_type: String, value: Variant) -> void:
	match value_type:
		"int":
			var val: Variant = _find_theme_property(theme_json, value, null)
			if val != null:
				theme.set_constant(property, theme_type, val)
		"color":
			var val: Variant = _find_theme_property(theme_json, value, null)
			if val != null:
				theme.set_color(property, theme_type, _array_to_color(val))
		"style_box_flat":
			var val: StyleBoxFlat = StyleBoxFlat.new()
			var properties: Array[bool] = [
				_add_sub_property(theme_json, val, value, "bg_color", SubPropertyType.COLOR),
				_add_sub_property(theme_json, val, value, "expand_margin_top", SubPropertyType.INT),
				_add_sub_property(theme_json, val, value, "expand_margin_bottom", SubPropertyType.INT),
				_add_sub_property(theme_json, val, value, "corner_radius_top_left", SubPropertyType.INT),
				_add_sub_property(theme_json, val, value, "corner_radius_top_right", SubPropertyType.INT),
				_add_sub_property(theme_json, val, value, "corner_radius_bottom_left", SubPropertyType.INT),
				_add_sub_property(theme_json, val, value, "corner_radius_bottom_right", SubPropertyType.INT),
			]
			if properties.any(func (b: bool) -> bool: return b):
				theme.set_stylebox(property, theme_type, val)

func _array_to_color(arr: Array) -> Color:
	return Color(arr[0] / 255.0, arr[1] / 255.0, arr[2] / 255.0)

func _add_sub_property(theme_json: Variant, obj: Object, value: Variant, property: String, type: SubPropertyType) -> bool:
	if not value.has(property):
		return false
	var val: Variant = _find_theme_property(theme_json, value[property], null)
	if val == null:
		return false
	match type:
		SubPropertyType.COLOR:
			obj.set(property, _array_to_color(val))
		SubPropertyType.INT:
			obj.set(property, val)
	return true
