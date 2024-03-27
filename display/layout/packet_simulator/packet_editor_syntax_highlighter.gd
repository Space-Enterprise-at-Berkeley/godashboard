extends SyntaxHighlighter
class_name PacketEditorSyntaxHighlighter

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text: String = get_text_edit().get_line(line)
	var highlights: Dictionary = {}
	var tokens: PackedStringArray = text.split(" ")
	var offset: int = 0
	for i in tokens.size():
		var token: String = tokens[i]
		if i == 0:
			
		offset += token.length() + 1
	return highlights
