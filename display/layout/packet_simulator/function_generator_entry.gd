extends PanelContainer
class_name FunctionGeneratorEntry

@onready var delete_button: Button = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Delete
@onready var destination_type: OptionButton = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/DestinationType
@onready var destination_ip: LineEdit = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/DestinationIP
@onready var source_ip: LineEdit = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/SourceIP
@onready var delay: LineEdit = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Delay
@onready var enabled_button: CheckButton = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Enabled
@onready var update_button: Button = $MarginContainer/FunctionGeneratorEntry/HBoxContainer/Update
@onready var function_text: LineEdit = $MarginContainer/FunctionGeneratorEntry/FunctionText
@onready var timer: Timer = $Timer

var expression: Expression = Expression.new()
var variables: PackedStringArray = PackedStringArray(["t"])

func _ready() -> void:
	delete_button.pressed.connect(queue_free)
	timer.timeout.connect(_execute)
	destination_type.item_selected.connect(_change_destination_type)
	update_button.pressed.connect(_update)

func _delete() -> void:
	queue_free()

func _change_destination_type(index: int) -> void:
	if index == Databus.AddressType.MONOCAST:
		destination_ip.editable = true
	else:
		destination_ip.editable = false
	if index == Databus.AddressType.LOCALHOST:
		source_ip.editable = true
	else:
		source_ip.editable = false

func _update() -> void:
	expression.parse(function_text.text, variables)

func _execute() -> void:
	if not enabled_button.button_pressed:
		return
	var timestamp: int = Databus.get_current_time()
	var value: Variant = expression.execute([timestamp])
	print(value)
