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
	
	func _init(type_p: TokenType, data_p: String, offset_p: int) -> void:
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
var preprocessors: Dictionary = {}
var exists: bool = false

func _ready() -> void:
	var file: FileAccess = FileAccess.open("res://config/config.jsonc", FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()
	var res: Variant = parse_config(text)
	expand_config(res)
	config = res
	exists = true
	config_update.emit()
	
	var generator: Variant = config["influxMapGenerator"]["mapping"]
	generate_influx_map("res://tmp/influx_map.jsonc", generator)
	var influx_map_file: FileAccess = FileAccess.open("res://tmp/influx_map.jsonc", FileAccess.READ)
	var influx_map_text: String = influx_map_file.get_as_text()
	influx_map_file.close()
	var influx_map: Variant = parse_config(influx_map_text)
	config["influxMap"] = influx_map

func parse_config(text: String) -> Variant:
	var tokens: Array[Token] = _lex(text)
	if len(tokens) == 0:
		return ParseError.new()
	var parsed: Variant = _parse(tokens)
	return parsed;

func expand_config(conf: Variant) -> void:
	var device_ids: Dictionary = conf["protoConfig"]["deviceIds"]
	var packet_defs: Array = conf["protoPackets"]
	var types: Dictionary = conf["protoTypes"]
	
	var boards: Dictionary = {}
	var ip_lookup: Dictionary = {}
	var packets: Dictionary = {}
	var channel_mappings: Dictionary = {}
	var reverse_channel_mappings: Dictionary = {}
	var outgoing_packets: Dictionary = {}
	
	for board_name: String in device_ids:
		var ip: String = "10.0.0.%d" % device_ids[board_name]
		boards[ip] = board_name
		ip_lookup[board_name] = ip
		packets[board_name] = {}
		outgoing_packets[board_name] = {}
		var channel_mapping: Dictionary = {}
		if conf["protoConfig"].has(board_name):
			for c: Dictionary in conf["protoConfig"][board_name]:
				channel_mapping[c["channel"]] = c["measure"]
				reverse_channel_mappings[c["measure"]] = [board_name, c["channel"]]
		channel_mappings[board_name] = channel_mapping
	
	device_ids["bcast"] = 0
	packets["bcast"] = {}
	outgoing_packets["bcast"] = {}
	for packet_def: Dictionary in packet_defs:
		for reader: String in packet_def["reads"]:
			if match_wildcard("GD", reader):
				for board_name: String in device_ids:
					for writer: String in packet_def["writes"]:
						if match_wildcard(board_name, writer) or (board_name == "bcast" and writer == "*"):
							var fields: Array[Array] = []
							if packet_def.get("payload") != null:
								var inital_prefix: String = "%s.%s" % [board_name, packet_def["name"]]
								generate_packet_reader(inital_prefix, packet_def["payload"], types, fields, channel_mappings, board_name)
							packets[board_name][str(packet_def["id"])] = fields
				break
		for writer: String in packet_def["writes"]:
			if match_wildcard("GD", writer):
				for board_name: String in device_ids:
					for reader: String in packet_def["reads"]:
						if match_wildcard(board_name, reader) or (board_name == "bcast" and reader == "*"):
							var fields: Array[Array] = []
							if packet_def.get("payload") != null:
								generate_packet_reader("", packet_def["payload"], types, fields, channel_mappings, board_name)
							outgoing_packets[board_name][packet_def["name"]] = [packet_def["id"], fields]
						break
				break
	
	device_ids.erase("bcast")
	
	var reverse_enum_lookup: Dictionary = {}
	for type: String in types:
		var type_def: Variant = types[type]
		if type_def is Dictionary:
			var enum_map: Dictionary = {}
			for key: String in type_def:
				enum_map[type_def[key]] = key
			reverse_enum_lookup[type] = enum_map
	
	conf["reverse_enum_lookup"] = reverse_enum_lookup
	conf["boards"] = boards
	conf["ip_lookup"] = ip_lookup
	conf["packets"] = packets
	conf["outgoing_packets"] = outgoing_packets
	conf["channel_mappings"] = channel_mappings
	conf["reverse_channel_mappings"] = reverse_channel_mappings

func generate_packet_reader(name_prefix: String, packet_type: String, types: Dictionary, fields: Array[Array], channel_mappings: Dictionary, board_name: String) -> void:
	for f: Dictionary in types[packet_type]:
		if f.has("array"):
			if f.get("channel", false):
				var segments: PackedStringArray = name_prefix.split(".", 1)
				var short_name_prefix: String = "%s.%s" % [board_name.substr(0, 2), segments[1]]
				for i: int in f["array"]:
					if channel_mappings[board_name].has(i):
						generate_packet_reader_field("%s.%s.%s" % [short_name_prefix, f["symbol"], channel_mappings[board_name][i]], f, types, fields, channel_mappings, board_name)
					else:
						generate_packet_reader_field("%s.%s.%d" % [name_prefix, f["symbol"], i], f, types, fields, channel_mappings, board_name)
			else:
				for i: int in f["array"]:
					generate_packet_reader_field("%s.%s.%d" % [name_prefix, f["symbol"], i], f, types, fields, channel_mappings, board_name)
		else:
			generate_packet_reader_field("%s.%s" % [name_prefix, f["symbol"]], f, types, fields, channel_mappings, board_name)

func generate_packet_reader_field(name_prefix: String, field: Dictionary, types: Dictionary, fields: Array[Array], channel_mappings: Dictionary, board_name: String) -> void:
	if name_prefix.begins_with("."):
		name_prefix = name_prefix.substr(1)
	var field_type: String = field["type"]
	var enum_type: String = field.get("enum", "")
	var channel: bool = field.get("channel", false)
	match field_type:
		"u8": fields.append([name_prefix, "asUInt8", enum_type, channel])
		"u16": fields.append([name_prefix, "asUInt16", enum_type, channel])
		"u32": fields.append([name_prefix, "asUInt32", enum_type, channel])
		"f32": fields.append([name_prefix, "asFloat", enum_type, channel])
		_: generate_packet_reader(name_prefix, field_type, types, fields, channel_mappings, board_name)

func generate_influx_map(path: String, generator: Array) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_line("\n\n\n// !!!!! This file is automatically generated. Do not edit it directly !!!!!\n\n\n")
	file.store_line("{")
	for board: String in config["packets"]:
		if board.begins_with("GD"):
			continue
		file.store_line("\n\t// *** %s ***\n" % board)
		for packet: String in config["packets"][board]:
			for field: Array in config["packets"][board][packet]:
				var mapped_name: String = _influx_map_generate_value(field[0], generator)
				if mapped_name == "":
					file.store_line("\t// \"%s\": \"\"," % field[0])
				else:
					file.store_line("\t\"%s\": \"%s\"," % [field[0], mapped_name])
			file.store_line("")
	file.store_line("\t\"\": \"\"")
	file.store_line("}")
	file.close()

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
				var string: String = res.get_string()
				if lexer[0] not in UNLEXED:
					tokens.append(Token.new(lexer[0], string, offset))
				offset += string.length()
				text = text.substr(string.length())
				break
		if not found:
			GoLogger.error("Unlexable token at index %s: %s ..." % [offset, text.substr(15)])
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
					GoLogger.error("Expected \":\" at index %s" % token.offset)
					return ParseError.new()
				var val: Variant = _parse(tokens)
				if val is ParseError:
					return ParseError.new()
				if key != "$schema":
					ret[key] = val
				if tokens[0].type != TokenType.BRACE_CLOSE and tokens.pop_front().type != TokenType.COMMA:
					GoLogger.error("Expected \",\" or \"}\" at index %s" % token.offset)
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
					GoLogger.error("Expected \",\" or \"]\" at index %s" % token.offset)
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
	GoLogger.error("Unexpected token at index %s: %s" % [token.offset, token.data])
	return ParseError.new()

func _parse_string(string: String) -> Variant:
	if string == "\"$schema\"":
		return "$schema"
	if string[1] == "$":
		var file: FileAccess = FileAccess.open("res://config/%s" %string.substr(2, string.length() - 3), FileAccess.READ)
		var text: String = file.get_as_text()
		var res: Variant = parse_config(text)
		return res
	var out: String = ""
	var escaped: bool = false
	for i in range(1, string.length() - 1):
		var chr: String = string[i]
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

func match_wildcard(matched: String, pattern: String) -> bool:
	var regex: RegEx = RegEx.new()
	regex.compile(pattern.replace("*", ".*"))
	return regex.search(matched) != null

func _influx_map_generate_value(key: String, generator: Array) -> String:
	for g: Dictionary in generator:
		var search: RegExMatch = _regex(g["pattern"]).search(key)
		if search != null and search.get_string() == key:
			return _influx_map_apply_generator(key, g)
	return ""

func _influx_map_apply_generator(key: String, generator: Dictionary) -> String:
	var state: Dictionary = {}
	var key_segments: PackedStringArray = key.split(".")
	for i in key_segments.size():
		state[str(i)] = key_segments[i]
	var transforms: Array = generator.get("transforms", [])
	for transform: Dictionary in transforms:
		var out: String = transform["out"]
		var execute: bool = true
		if transform.has("if"):
			var conditional: Dictionary = transform["if"]
			match conditional["cond"]:
				"eq":
					if _influx_map_generator_parse_string(conditional["a"], state) != _influx_map_generator_parse_string(conditional["b"], state):
						execute = false
		if not execute:
			continue
		match transform["type"]:
			"substr":
				state[out] = state[transform["in"]].substr(transform["start"], transform["len"])
			"func":
				match transform["func"]:
					"camel": state[out] = state[transform["in"]].to_camel_case()
					"pascal": state[out] = state[transform["in"]].to_pascal_case()
			"const":
				state[out] = _influx_map_generator_parse_string(transform["value"], state)
	return _influx_map_generator_parse_string(generator["output"], state)

func _influx_map_generator_parse_string(string: String, state: Dictionary) -> String:
	var builder: PackedStringArray = PackedStringArray()
	var i: int = 0
	while i < string.length():
		if string[i] == "@":
			i += 1
			builder.append(state[string[i]])
		else:
			builder.append(string[i])
		i += 1
	return "".join(builder)
