extends Control

@export var field: String = "pt1.ptValue0"
@export var units: String = "PSI"

@onready var value_label: Label = $VBoxContainer/Label2

func _ready() -> void:
	#Databus.connect(field, update_field)
	pass

func _process(delta: float) -> void:
	pass

func update_field(value) -> void:
	value_label.text = str(value) + " " + units
