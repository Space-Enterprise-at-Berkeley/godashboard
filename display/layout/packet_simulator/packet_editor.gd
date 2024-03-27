extends VBoxContainer
class_name PacketEditor

@onready var text_edit: TextEdit = $TextEdit

func _ready() -> void:
	text_edit.syntax_highlighter = PacketEditorSyntaxHighlighter.new()
