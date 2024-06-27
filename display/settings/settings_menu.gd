extends PopupPanel
class_name SettingsMenu

@onready var display_root: Control = $CanvasLayer/DisplayRoot
@onready var influx_connect: Button = $CanvasLayer/DisplayRoot/MarginContainer/VBoxContainer/HBoxContainer/InfluxSettings/InfluxConnect
@onready var influx_select_database: OptionButton = $CanvasLayer/DisplayRoot/MarginContainer/VBoxContainer/HBoxContainer/InfluxSettings/InfluxSelectDatabase
@onready var influx_start: Button = $CanvasLayer/DisplayRoot/MarginContainer/VBoxContainer/HBoxContainer/InfluxSettings/InfluxStart

func _ready() -> void:
	influx_connect.pressed.connect(_influx_connect)
	influx_select_database.item_selected.connect(_select_database)
	influx_start.pressed.connect(_influx_start)
	Influx.found_databases.connect(_update_influx_databases)

func display() -> void:
	display_root.theme = Globals.theme
	popup_centered()

func _influx_connect() -> void:
	Influx.list_databases()

func _update_influx_databases(databases: Array) -> void:
	Logger.debug(databases)
	influx_select_database.clear()
	var reversed: Array = databases.duplicate()
	reversed.reverse()
	for db: String in reversed:
		influx_select_database.add_item(db)
	influx_select_database.disabled = false

func _select_database(idx: int) -> void:
	if idx < 0:
		return
	influx_start.disabled = false

func _influx_start() -> void:
	var db_name: String = influx_select_database.get_item_text(influx_select_database.get_selected_id())
	Influx.init(db_name)
