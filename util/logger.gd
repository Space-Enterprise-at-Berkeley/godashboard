extends Node

signal entry(msg: String, level: LogLevel, timestamp: int)

enum LogLevel {
	DEBUG,
	INFO,
	WARN,
	ERROR,
}

const LOG_LEVEL_NAMES: Dictionary = {
	LogLevel.DEBUG: "DEBUG",
	LogLevel.INFO: "INFO",
	LogLevel.WARN: "WARN",
	LogLevel.ERROR: "ERROR"
}

var file: FileAccess = null

func _ready() -> void:
	if file == null:
		file = FileAccess.open("res://logs/%s.txt" %Time.get_datetime_string_from_system().replace(":", "-"), FileAccess.WRITE)

func record(msg: String, level: LogLevel) -> void:
	if file == null:
		file = FileAccess.open("res://logs/%s.txt" %Time.get_datetime_string_from_system().replace(":", "-"), FileAccess.WRITE)
	var timestamp: int = Databus.get_current_time()
	var timestring: String = Time.get_datetime_string_from_system()
	file.store_line("[%s] [%s] %s" %[LOG_LEVEL_NAMES[level], timestring, msg])
	file.flush()
	entry.emit(msg, level, timestamp)

func debug(msg: String) -> void:
	record(msg, LogLevel.DEBUG)

func info(msg: String) -> void:
	record(msg, LogLevel.INFO)

func warn(msg: String) -> void:
	record(msg, LogLevel.WARN)

func error(msg: String) -> void:
	record(msg, LogLevel.ERROR)
