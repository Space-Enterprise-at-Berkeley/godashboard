extends Control
class_name LogsSquare

enum FilterType {
	ANY,
	ALL,
}

@onready var text_box: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var filters_dropdown: MenuButton = $VBoxContainer/MarginContainer/Filters

var filters: Dictionary = {
	"debug": [false, FilterType.ANY, func (m: String, l: Logger.LogLevel, t: int) -> bool: return l == Logger.LogLevel.DEBUG],
	"info": [true, FilterType.ANY, func (m: String, l: Logger.LogLevel, t: int) -> bool: return l == Logger.LogLevel.INFO],
	"warn": [true, FilterType.ANY, func (m: String, l: Logger.LogLevel, t: int) -> bool: return l == Logger.LogLevel.WARN],
	"error": [true, FilterType.ANY, func (m: String, l: Logger.LogLevel, t: int) -> bool: return l == Logger.LogLevel.ERROR],
}
var log_history: Array = []
var colors: Dictionary = {}
var filters_dropdown_order: Array[String] = []

func _ready() -> void:
	Logger.entry.connect(_on_log_entry)
	colors[Logger.LogLevel.DEBUG] = Globals.theme.get_color("log_level_debug", "Global")
	colors[Logger.LogLevel.INFO] = Globals.theme.get_color("log_level_info", "Global")
	colors[Logger.LogLevel.WARN] = Globals.theme.get_color("log_level_warn", "Global")
	colors[Logger.LogLevel.ERROR] = Globals.theme.get_color("log_level_error", "Global")
	var dropdown: PopupMenu = filters_dropdown.get_popup()
	for filter: String in filters:
		filters_dropdown_order.append(filter)
		dropdown.add_check_item(filter)
		if filters[filter][0]:
			dropdown.set_item_checked(filters_dropdown_order.size() - 1, true)
	dropdown.index_pressed.connect(_toggle_filter)
	dropdown.hide_on_checkable_item_selection = false

func _on_log_entry(msg: String, level: Logger.LogLevel, timestamp: int) -> void:
	log_history.append([msg, level, timestamp])
	var filter_check: bool = _check_filters(msg, level, timestamp)
	if filter_check:
		_display_entry(msg, level, timestamp)

func _check_filters(msg: String, level: Logger.LogLevel, timestamp: int) -> bool:
	var any_found: bool = false
	for f: String in filters:
		var filter: Array = filters[f]
		if not filter[0]:
			continue
		var result: bool = filter[2].call(msg, level, timestamp)
		if filter[1] == FilterType.ANY and result:
			any_found = true
		if filter[1] == FilterType.ALL and not result:
			return false
	return any_found

func _display_entry(msg: String, level: Logger.LogLevel, timestamp: int) -> void:
	var timestring: String = Time.get_datetime_string_from_unix_time(timestamp / 1000).split("T")[1]
	text_box.push_color(colors[level])
	text_box.add_text("[")
	text_box.add_text(Logger.LOG_LEVEL_NAMES[level])
	text_box.add_text("]")
	text_box.pop()
	text_box.add_text(" [")
	text_box.add_text(timestring)
	text_box.add_text("] ")
	text_box.add_text(msg)
	text_box.newline()

func _refresh() -> void:
	text_box.clear()
	for event: Array in log_history:
		var filter_check: bool = _check_filters(event[0], event[1], event[2])
		if filter_check:
			_display_entry(event[0], event[1], event[2])

func _toggle_filter(index: int) -> void:
	var popup: PopupMenu = filters_dropdown.get_popup()
	var new_state: bool = not popup.is_item_checked(index)
	popup.set_item_checked(index, new_state)
	filters[filters_dropdown_order[index]][0] = new_state
	_refresh()
