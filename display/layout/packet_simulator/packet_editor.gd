extends VBoxContainer
class_name PacketEditor

signal submit

@onready var text_edit: TextEdit = $TextEdit

func _ready() -> void:
	text_edit.syntax_highlighter = PacketEditorSyntaxHighlighter.new()

func _input(event: InputEvent) -> void:
	if text_edit.has_focus() and event.is_pressed():
		if event is InputEventKey:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				submit.emit()
				get_viewport().set_input_as_handled()
