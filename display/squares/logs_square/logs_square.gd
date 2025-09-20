extends Control
class_name LogsSquare

enum FilterType {
	ANY,
	ALL,
}

@onready var text_box: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var filters_dropdown: MenuButton = $VBoxContainer/MarginContainer/Filters
@onready var chat: TextEdit = $VBoxContainer/Chat

var filters: Dictionary = {
	"debug": [false, FilterType.ANY, func (m: String, l: GoLogger.LogLevel, t: int) -> bool: return l == GoLogger.LogLevel.DEBUG],
	"info": [true, FilterType.ANY, func (m: String, l: GoLogger.LogLevel, t: int) -> bool: return l == GoLogger.LogLevel.INFO],
	"warn": [true, FilterType.ANY, func (m: String, l: GoLogger.LogLevel, t: int) -> bool: return l == GoLogger.LogLevel.WARN],
	"error": [true, FilterType.ANY, func (m: String, l: GoLogger.LogLevel, t: int) -> bool: return l == GoLogger.LogLevel.ERROR],
	"chat": [true, FilterType.ANY, func (m: String, l: GoLogger.LogLevel, t: int) -> bool: return l == GoLogger.LogLevel.CHAT],
	"achievement": [true, FilterType.ANY, func (m: String, l: GoLogger.LogLevel, t: int) -> bool: return l == GoLogger.LogLevel.ACHIEVEMENT],
}
var log_history: Array = []
var colors: Dictionary = {}
var filters_dropdown_order: Array[String] = []

func _ready() -> void:
	GoLogger.entry.connect(_on_log_entry)
	colors[GoLogger.LogLevel.DEBUG] = Globals.theme.get_color("log_level_debug", "Global")
	colors[GoLogger.LogLevel.INFO] = Globals.theme.get_color("log_level_info", "Global")
	colors[GoLogger.LogLevel.WARN] = Globals.theme.get_color("log_level_warn", "Global")
	colors[GoLogger.LogLevel.ERROR] = Globals.theme.get_color("log_level_error", "Global")
	colors[GoLogger.LogLevel.CHAT] = Globals.theme.get_color("log_level_chat", "Global")
	colors[GoLogger.LogLevel.ACHIEVEMENT] = Globals.theme.get_color("log_level_achievement", "Global")
	var dropdown: PopupMenu = filters_dropdown.get_popup()
	for filter: String in filters:
		filters_dropdown_order.append(filter)
		dropdown.add_check_item(filter)
		if filters[filter][0]:
			dropdown.set_item_checked(filters_dropdown_order.size() - 1, true)
	dropdown.index_pressed.connect(_toggle_filter)
	dropdown.hide_on_checkable_item_selection = false

func _on_log_entry(msg: String, level: GoLogger.LogLevel, timestamp: int) -> void:
	log_history.append([msg, level, timestamp])
	var filter_check: bool = _check_filters(msg, level, timestamp)
	if filter_check:
		_display_entry(msg, level, timestamp)

func _check_filters(msg: String, level: GoLogger.LogLevel, timestamp: int) -> bool:
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

func _display_entry(msg: String, level: GoLogger.LogLevel, timestamp: int) -> void:
	var timestring: String = Time.get_datetime_string_from_unix_time(timestamp / 1000).split("T")[1]
	text_box.push_color(colors[level])
	text_box.add_text("[")
	text_box.add_text(GoLogger.LOG_LEVEL_NAMES[level])
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

func _input(event: InputEvent) -> void:
	if chat.has_focus() and event.is_pressed():
		if event is InputEventKey:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				_send_chat()
				get_viewport().set_input_as_handled()

func _send_chat() -> void:
	var user: String = OS.get_environment("USERNAME")
	var msg: String = JSON.stringify({
		"type": "chat",
		"message": chat.text,
		"sender": user
	})
	GoLogger.chat("(%s) %s" % [user, chat.text])
	Comms.chat_server.put_packet(msg.to_utf8_buffer())
	chat.clear()
