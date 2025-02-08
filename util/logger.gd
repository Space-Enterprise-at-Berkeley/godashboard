extends Node

signal entry(msg: String, level: LogLevel, timestamp: int)

enum LogLevel {
	DEBUG,
	INFO,
	WARN,
	ERROR,
	CHAT,
	ACHIEVEMENT,
}

const LOG_LEVEL_NAMES: Dictionary = {
	LogLevel.DEBUG: "DEBUG",
	LogLevel.INFO: "INFO",
	LogLevel.WARN: "WARN",
	LogLevel.ERROR: "ERROR",
	LogLevel.CHAT: "CHAT",
	LogLevel.ACHIEVEMENT: "ACHIEV"
}

var file: FileAccess = null

func _ready() -> void:
	var dir: DirAccess = DirAccess.open("res://logs")
	var files: PackedStringArray = dir.get_files()
	for i in len(files) - 5:
		dir.remove(files[i])
	if file == null:
		file = FileAccess.open("res://logs/%s.txt" % Time.get_datetime_string_from_system().replace(":", "-"), FileAccess.WRITE)

func record(msg: Variant, level: LogLevel) -> void:
	var m: String = str(msg)
	if file == null:
		file = FileAccess.open("res://logs/%s.txt" % Time.get_datetime_string_from_system().replace(":", "-"), FileAccess.WRITE)
	var timestamp: int = Databus.get_current_time()
	var timestring: String = Time.get_datetime_string_from_system()
	file.store_line("[%s] [%s] %s" % [LOG_LEVEL_NAMES[level], timestring, m])
	file.flush()
	entry.emit(m, level, timestamp)

func debug(msg: Variant) -> void:
	record(msg, LogLevel.DEBUG)

func info(msg: Variant) -> void:
	record(msg, LogLevel.INFO)

func warn(msg: Variant) -> void:
	record(msg, LogLevel.WARN)

func error(msg: Variant) -> void:
	record(msg, LogLevel.ERROR)

func chat(msg: Variant) -> void:
	record(msg, LogLevel.CHAT)

func achievement(msg: Variant) -> void:
	record(msg, LogLevel.ACHIEVEMENT)
