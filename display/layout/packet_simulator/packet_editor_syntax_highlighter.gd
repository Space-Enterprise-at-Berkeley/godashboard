extends SyntaxHighlighter
class_name PacketEditorSyntaxHighlighter

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	if get_text_edit().text.length() == 0:
		return {}
	var text: String = get_text_edit().get_line(line)
	var highlights: Dictionary = {}
	var tokens: PackedStringArray = text.split(" ")
	var offset: int = 0
	for i in tokens.size():
		var token: String = tokens[i]
		if i == 0:
			highlights[offset] = {"color": Globals.theme.get_color("packet_editor_ip", "Global")}
		if i == 1:
			highlights[offset] = {"color": Globals.theme.get_color("packet_editor_id", "Global")}
		if i == 2:
			highlights[offset] = {"color": Globals.theme.get_color("packet_editor_value", "Global")}
		offset += token.length() + 1
	return highlights
