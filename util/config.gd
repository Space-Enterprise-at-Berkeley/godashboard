extends Node

signal config_update

enum TokenType {
	BRACE_OPEN,
	BRACE_CLOSE,
	BRACKET_OPEN,
	BRACKET_CLOSE,
	COMMA,
	COLON,
	BOOLEAN,
	NULL,
	NUMBER_BIN,
	NUMBER_HEX,
	NUMBER_INT,
	NUMBER_FLOAT,
	STRING,
	COMMENT,
	WHITESPACE,
}

class Token:
	
	var type: TokenType
	var data: String
	var offset: int
	
	func _init(type_p: TokenType, data_p: String, offset_p: int):
		type = type_p
		data = data_p
		offset = offset_p

class ParseError:
	pass

var LEXERS: Array[Array] = [
	[TokenType.BRACE_OPEN, _regex("^\\{")],
	[TokenType.BRACE_CLOSE, _regex("^\\}")],
	[TokenType.BRACKET_OPEN, _regex("^\\[")],
	[TokenType.BRACKET_CLOSE, _regex("^\\]")],
	[TokenType.COMMA, _regex("^,")],
	[TokenType.COLON, _regex("^:")],
	[TokenType.BOOLEAN, _regex("^(?:true|false)")],
	[TokenType.NULL, _regex("^null")],
	[TokenType.NUMBER_BIN, _regex("^[-+]?0b[0-1]+")],
	[TokenType.NUMBER_HEX, _regex("^[-+]?0x[0-9a-fA-F]+")],
	[TokenType.NUMBER_FLOAT, _regex("^[-+]?[0-9]+[\\.e][0-9]+")],
	[TokenType.NUMBER_INT, _regex("^[-+]?[0-9]+")],
	[TokenType.STRING, _regex("^\"(?:[^\"\\\\]|\\\\.)*\"")],
	[TokenType.COMMENT, _regex("^//.*")],
	[TokenType.COMMENT, _regex("^/\\*[\\S\\s]*?\\*/")],
	[TokenType.WHITESPACE, _regex("^\\s+")],
]

const UNLEXED: Array[TokenType] = [TokenType.COMMENT, TokenType.WHITESPACE]

var config: Variant = {}
var exists: bool = false

func _ready() -> void:
	var file: FileAccess = FileAccess.open("res://config/config.jsonc", FileAccess.READ)
	var text: String = file.get_as_text()
	var res: Variant = parse_config(text)
	config = res
	exists = true
	config_update.emit()

func parse_config(text: String) -> Variant:
	var tokens: Array[Token] = _lex(text)
	#print(tokens.map(func (e: Token) -> String: return TokenType.keys()[e.type]))
	if len(tokens) == 0:
		return ParseError.new()
	var parsed: Variant = _parse(tokens)
	return parsed;

func _regex(pattern: String) -> RegEx:
	var re: RegEx = RegEx.new()
	re.compile(pattern)
	return re

func _lex(text: String) -> Array[Token]:
	var tokens: Array[Token] = []
	var offset: int = 0
	while text.length() > 0:
		var found: bool = false
		for lexer in LEXERS:
			var res: RegExMatch = lexer[1].search(text)
			if res:
				found = true
				var str: String = res.get_string()
				if lexer[0] not in UNLEXED:
					tokens.append(Token.new(lexer[0], str, offset))
				offset += str.length()
				text = text.substr(str.length())
				break
		if not found:
			push_error("Unlexable token at index %s: %s ..." % [offset, text.substr(15)])
			return []
	return tokens

func _parse(tokens: Array[Token]) -> Variant:
	var token: Token = tokens.pop_front()
	var value: String = token.data
	match token.type:
		TokenType.BRACE_OPEN:
			var ret: Dictionary = {}
			while true:
				if tokens[0].type == TokenType.BRACE_CLOSE:
					tokens.pop_front()
					return ret
				var key: Variant = _parse(tokens)
				if key is ParseError:
					return ParseError.new()
				if tokens.pop_front().type != TokenType.COLON:
					push_error("Expected \":\" at index %s" % token.offset)
					return ParseError.new()
				var val: Variant = _parse(tokens)
				if val is ParseError:
					return ParseError.new()
				ret[key] = val
				if tokens[0].type != TokenType.BRACE_CLOSE and tokens.pop_front().type != TokenType.COMMA:
					push_error("Expected \",\" or \"}\" at index %s" % token.offset)
					return ParseError.new()
		TokenType.BRACKET_OPEN:
			var ret: Array = []
			while true:
				if tokens[0].type == TokenType.BRACKET_CLOSE:
					tokens.pop_front()
					return ret
				var val: Variant = _parse(tokens)
				if val is ParseError:
					return ParseError.new()
				ret.append(val)
				if tokens[0].type != TokenType.BRACKET_CLOSE and tokens.pop_front().type != TokenType.COMMA:
					push_error("Expected \",\" or \"]\" at index %s" % token.offset)
					return ParseError.new()
		TokenType.BOOLEAN:
			return value == "true"
		TokenType.NULL:
			return null
		TokenType.NUMBER_BIN:
			if value[0] == "+":
				value = value.substr(1)
			return value.bin_to_int()
		TokenType.NUMBER_HEX:
			if value[0] == "+":
				value = value.substr(1)
			return value.hex_to_int()
		TokenType.NUMBER_FLOAT:
			return value.to_float()
		TokenType.NUMBER_INT:
			return value.to_int()
		TokenType.STRING:
			return _parse_string(value)
	push_error("Unexpected token at index %s: %s" % token.offset, token.data)
	return ParseError.new()

func _parse_string(str: String) -> Variant:
	if str[1] == "$":
		var file: FileAccess = FileAccess.open("res://config/%s" %str.substr(2, str.length() - 3), FileAccess.READ)
		var text: String = file.get_as_text()
		var res: Variant = parse_config(text)
		return res
	var out: String = ""
	var escaped: bool = false
	for i in range(1, str.length() - 1):
		var chr: String = str[i]
		if not escaped:
			if chr == "\\":
				escaped = true
			else:
				out += chr
		else:
			escaped = false
			match chr:
				"a":
					out += "\a"
				"b":
					out += "\b"
				"f":
					out += "\f"
				"n":
					out += "\n"
				"r":
					out += "\r"
				"t":
					out += "\t"
				"v":
					out += "\v"
				"'":
					out += "'"
				"\"":
					out += "\""
				"\\":
					out += "\\"
				_:
					out += chr
	return out
