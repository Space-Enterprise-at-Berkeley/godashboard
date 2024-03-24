extends Node

signal update(fields, timestamp)

class Packet:
	var fields: Dictionary
	var timestamp: int
	var error: bool

var ip_cache: Dictionary = {}
var first_receive_times: Dictionary = {}
var first_receive_offsets: Dictionary = {}
var has_config: bool = false
var connected_timers: Dictionary = {}
var boards_connected: Dictionary = {}
var boards_kbps: Dictionary = {}
const TYPE_LENGTHS: Dictionary = {
	"asASCIIString": 0,
	"asFloat": 4,
	"asUInt8": 1,
	"asUInt16": 2,
	"asUInt32": 4,
}

func _ready() -> void:
	Config.config_update.connect(_config_update)
	_board_poll_kbps()

func _config_update() -> void:
	ip_cache = {}
	for child in get_children():
		child.queue_free()
	for name in Config.config["boards"]:
		ip_cache[Config.config["boards"][name]["address"]] = name
		first_receive_times[name] = -1
		first_receive_offsets[name] = -1
		boards_kbps[name] = 0
		boards_connected[name] = false
	has_config = true

func process_packet(data: PackedByteArray, addr: String) -> void:
	var packet: Packet = _parse_packet(data, addr)
	if not packet.error:
		update.emit(packet.fields, packet.timestamp)

func _parse_packet(data: PackedByteArray, addr: String) -> Packet:
	var packet: Packet = Packet.new()
	if not has_config:
		packet.error = true
		return packet
	if not ip_cache.has(addr):
		packet.error = true
		return packet
	var board: String = ip_cache[addr]
	boards_kbps[board] += data.size() / 125.0
	var id: int = data.decode_u8(0)
	var length: int = data.decode_u8(1)
	var run_time: int = data.decode_u32(2)
	var timestamp: int = _calculate_timestamp(run_time, board)
	var checksum: int = data.decode_u16(6)
	var field_data: PackedByteArray = data.slice(8, 8 + length)
	var sum_buf: PackedByteArray = data.slice(0, 6) + field_data
	var expected_checksum: int = fletcher16(sum_buf)
	if expected_checksum != checksum:
		packet.error = true
		return packet
	var board_type: String = Config.config["boards"][board]["type"]
	var e = Config.config["packets"][board_type]
	if not Config.config["packets"][board_type].has(str(id)):
		packet.error = true
		return packet
	var definition: Array = Config.config["packets"][board_type][str(id)]
	var mapped_update: Dictionary = {}
	var influx_map: Dictionary = Config.config["influxMap"]
	var offset = 0
	for field in definition:
		var full_name: String = "%s.%s" %[board, field[0]]
		var val: Variant = _read_value(field_data, offset, field[1])
		offset += TYPE_LENGTHS[field[1]]
		if not influx_map.has(full_name):
			influx_map[full_name] = full_name
		mapped_update[influx_map[full_name]] = val
	packet.fields = mapped_update
	packet.timestamp = timestamp
	packet.error = false
	return packet

func _calculate_timestamp(run_time: int, board: String) -> int:
	if (first_receive_times[board] < 0):
		first_receive_times[board] = get_current_time()
	if (first_receive_offsets[board] < 0):
		first_receive_offsets[board] = run_time
	return run_time - first_receive_offsets[board] + first_receive_times[board]

func _read_value(buf: PackedByteArray, offset: int, type: String) -> Variant:
	match type:
		"asASCIIString":
			return buf.get_string_from_utf8()
		"asFloat":
			return buf.decode_float(offset)
		"asUInt8":
			return buf.decode_u8(offset)
		"asUInt16":
			return buf.decode_u16(offset)
		"asUInt32":
			return buf.decode_u32(offset)
	return null

func send_update(fields: Dictionary, timestamp: int) -> void:
	update.emit(fields, timestamp)

func fletcher16(data: PackedByteArray) -> int:
	var a: int = 0
	var b: int = 0
	for i in data.size():
		a = (a + data[i]) % 256
		b = (b + a) % 256
	return a | (b << 8)

func get_current_time() -> int:
	return int(Time.get_unix_time_from_system() * 1000)

func _board_poll_kbps() -> void:
	while true:
		var update: Dictionary = {}
		for board in boards_connected:
			var kbps: int = boards_kbps[board]
			boards_kbps[board] = 0
			update["%sKbps" %board] = kbps
			if kbps != 0 and not boards_connected[board]:
				update["%sConnected" %board] = true
			elif kbps == 0 and boards_connected[board]:
				update["%sConnected" %board] = false
			send_update(update, get_current_time())
		await get_tree().create_timer(1).timeout
