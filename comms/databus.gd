extends Node

signal update(fields: Dictionary, timestamp: int)

enum AddressType {
	MONOCAST,
	MULTICAST,
	BROADCAST,
	LOCALHOST,
}

enum PacketDataType {
	ASCII_STRING,
	FLOAT,
	UINT8,
	UINT16,
	UINT32,
}

class Packet:
	var fields: Dictionary
	var timestamp: int
	var error: bool

const TYPE_LENGTHS: Dictionary = {
	PacketDataType.ASCII_STRING: 0,
	PacketDataType.FLOAT: 4,
	PacketDataType.UINT8: 1,
	PacketDataType.UINT16: 2,
	PacketDataType.UINT32: 4,
}

const TYPE_NAME_LOOKUP: Dictionary = {
	"asASCIIString": PacketDataType.ASCII_STRING,
	"asFloat": PacketDataType.FLOAT,
	"asUInt8": PacketDataType.UINT8,
	"asUInt16": PacketDataType.UINT16,
	"asUInt32": PacketDataType.UINT32,
}

enum AbortReason {
	MANUAL = 0,
	NOS_OVERPRESSURE = 1,
	IPA_OVERPRESSURE = 2,
	ENGINE_OVERTEMP = 3,
	FAILED_IGNITION = 4,
	IGNITER_NO_CONTINUITY = 5,
	BREAKWIRE_NO_CONTINUITY = 6,
	BREAKWIRE_NO_BURNT = 7,
	NO_DASHBOARD_COMMS = 8,
	PROPELLANT_RUN_OUT = 9,
}

const ABORT_DESCRIPTIONS: Dictionary = {
	AbortReason.MANUAL: "Manual",
	AbortReason.NOS_OVERPRESSURE: "NOS Overpressure",
	AbortReason.IPA_OVERPRESSURE: "IPA Overpressure",
	AbortReason.ENGINE_OVERTEMP: "Engine Overtemp",
	AbortReason.FAILED_IGNITION: "Failed Ignition",
	AbortReason.IGNITER_NO_CONTINUITY: "Igniter No Continuity",
	AbortReason.BREAKWIRE_NO_CONTINUITY: "Breakwire No Continuity",
	AbortReason.BREAKWIRE_NO_BURNT: "Breakwire No Burnt",
	AbortReason.NO_DASHBOARD_COMMS: "No Dashboard Comms",
	AbortReason.PROPELLANT_RUN_OUT: "Propellant Run-Out",
}

const LAUNCH_ID: int = 200
const ABORT_ID: int = 133

var ip_cache: Dictionary = {}
var first_receive_times: Dictionary = {}
var first_receive_offsets: Dictionary = {}
var last_packet_times: Dictionary = {}
var has_config: bool = false
var connected_timers: Dictionary = {}
var boards_connected: Dictionary = {}
var boards_kbps: Dictionary = {}

func _ready() -> void:
	Config.config_update.connect(_config_update)
	if Config.exists:
		_config_update()
	_board_poll_kbps()

func _config_update() -> void:
	ip_cache = {}
	for child in get_children():
		child.queue_free()
	for board_name: String in Config.config["boards"]:
		ip_cache[Config.config["boards"][board_name]["address"]] = board_name
		first_receive_times[board_name] = -1
		first_receive_offsets[board_name] = -1
		last_packet_times[board_name] = 0
		boards_kbps[board_name] = 0.0
		boards_connected[board_name] = false
	has_config = true
	for camera: Dictionary in Config.config["cameras"]:
		add_child(Camera.register_camera(camera["id"], camera["name"], camera["ip"]))

func process_packet(data: PackedByteArray, addr: String) -> void:
	if addr == Comms.LOCALHOST_IP:
		var addr_len: int = data.decode_u8(0)
		var addr_buf: PackedByteArray = data.slice(1, 1 + addr_len)
		addr = addr_buf.get_string_from_ascii()
		data = data.slice(1 + addr_len)
	var packet: Packet = _parse_packet(data, addr)
	if not packet.error:
		for field: String in packet.fields:
			if Config.preprocessors.has(field):
				for pre: String in Config.preprocessors[field]:
					packet.fields[pre] = Config.preprocessors[field][pre].process_data(packet.fields[field], packet.timestamp)
		update.emit(packet.fields, packet.timestamp)

func register_field(field: String) -> void:
	if not field.contains("@"):
		return
	var field_data: PackedStringArray = field.split("@")
	if not Config.preprocessors.has(field_data[0]):
		Config.preprocessors[field_data[0]] = {}
	if not Config.preprocessors[field_data[0]].has(field_data[1]):
		Config.preprocessors[field_data[0]][field] = Preprocessor.get_preprocessor(field_data[0], field_data[1])

func _parse_packet(data: PackedByteArray, addr: String) -> Packet:
	var packet: Packet = Packet.new()
	if not has_config:
		Logger.warn("Config not ready to parse packet")
		packet.error = true
		return packet
	if not ip_cache.has(addr):
		Logger.debug("IP %s not recognized" % addr)
		packet.error = true
		return packet
	var board: String = ip_cache[addr]
	boards_kbps[board] += data.size() / 125.0
	var id: int = data.decode_u8(0)
	var length: int = data.decode_u8(1)
	var run_time: int = data.decode_u32(2)
	if run_time < 1000 and last_packet_times[board] > 1500 and last_packet_times[board] < 4294966295: # UINT_32_MAX - 1000
		first_receive_times[board] = -1
		first_receive_offsets[board] = -1
		Logger.info("Resetting timestamps for %s" % board)
	last_packet_times[board] = run_time
	var timestamp: int = _calculate_timestamp(run_time, board)
	var checksum: int = data.decode_u16(6)
	var field_data: PackedByteArray = data.slice(8, 8 + length)
	var sum_buf: PackedByteArray = data.slice(0, 6) + field_data
	var expected_checksum: int = fletcher16(sum_buf)
	
	# Abort stuff - should be moved elsewhere and done better
	if id == 133:
		var abort_reason: int = field_data.decode_u8(1)
		Logger.warn("Abort reason: %d (%s)" % [abort_reason, ABORT_DESCRIPTIONS[abort_reason]])
	
	if expected_checksum != checksum:
		Logger.warn("Invalid checksum from board %s (packet id %d)" % [board, id])
		packet.error = true
		return packet
	var board_type: String = Config.config["boards"][board]["type"]
	if not Config.config["packets"][board_type].has(str(id)):
		Logger.debug("Unrecognized packet %d on board %s" % [id, board])
		packet.error = true
		return packet
	var definition: Array = Config.config["packets"][board_type][str(id)]
	var mapped_update: Dictionary = {}
	var influx_map: Dictionary = Config.config["influxMap"]
	var offset: int = 0
	for field: Array in definition:
		var full_name: String = "%s.%s" %[board, field[0]]
		var type: PacketDataType = TYPE_NAME_LOOKUP[field[1]]
		var val: Variant = _read_value(field_data, offset, type)
		offset += TYPE_LENGTHS[type]
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

func _read_value(buf: PackedByteArray, offset: int, type: PacketDataType) -> Variant:
	match type:
		PacketDataType.ASCII_STRING:
			return buf.get_string_from_utf8()
		PacketDataType.FLOAT:
			return buf.decode_float(offset)
		PacketDataType.UINT8:
			return buf.decode_u8(offset)
		PacketDataType.UINT16:
			return buf.decode_u16(offset)
		PacketDataType.UINT32:
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
		if not Config.exists:
			return
		var update_data: Dictionary = {}
		for board: String in boards_connected:
			var kbps: float = boards_kbps[board]
			boards_kbps[board] = 0
			update_data["%sKbps" %board] = kbps
			if not is_zero_approx(kbps) and not boards_connected[board]:
				boards_connected[board] = true
				update_data["%sConnected" % board] = true
				Logger.info("Board connected: %s" % board)
			elif is_zero_approx(kbps) and boards_connected[board]:
				boards_connected[board] = false
				update_data["%sConnected" % board] = false
				first_receive_times[board] = -1
				first_receive_offsets[board] = -1
				Logger.info("Resetting timestamps for %s" % board)
				Logger.warn("Board disconnected: %s" % board)
			send_update(update_data, get_current_time())
		await get_tree().create_timer(1).timeout

func _encode_value(value: Variant, type: PacketDataType) -> PackedByteArray:
	var buf: PackedByteArray = PackedByteArray()
	buf.resize(TYPE_LENGTHS[type])
	match type:
		PacketDataType.FLOAT:
			buf.encode_float(0, value)
		PacketDataType.UINT8:
			buf.encode_u8(0, value)
		PacketDataType.UINT16:
			buf.encode_u16(0, value)
		PacketDataType.UINT32:
			buf.encode_u32(0, value)
	return buf

func _get_ip(ip: String) -> Array:
	if ip.begins_with("localhost/") or ip.begins_with(Comms.LOCALHOST_IP + "/"):
		var dest_ip: Array = _get_ip(ip.split("/")[1])
		return [AddressType.LOCALHOST, dest_ip[1]]
	if ip == "mcast" or ip == Comms.MCAST_IP:
		return [AddressType.MULTICAST, null]
	if ip == "bcast" or ip == Comms.BCAST_IP or ip == "255":
		return [AddressType.BROADCAST, null]
	if ip.is_valid_int():
		return [AddressType.MONOCAST, "10.0.0.%d" %ip.to_int()]
	var board: Variant = Config.config["boards"].get(ip, null)
	if board != null:
		return [AddressType.MONOCAST, board["address"]]
	return [AddressType.MONOCAST, ip]

func send_packet(ip: String, id: int, args: Array) -> void:
	var output_buffer: PackedByteArray = PackedByteArray()
	var parsed_ip: Array = _get_ip(ip)
	if parsed_ip[0] == AddressType.LOCALHOST:
		if parsed_ip[1].length() == 0:
			return
		output_buffer.append_array(_encode_value(parsed_ip[1].length(), PacketDataType.UINT8))
		output_buffer.append_array(parsed_ip[1].to_ascii_buffer())
	var id_buffer: PackedByteArray = _encode_value(id, PacketDataType.UINT8)
	var args_buffer: PackedByteArray = PackedByteArray()
	for arg: Array in args:
		args_buffer.append_array(_encode_value(arg[0], arg[1]))
	var length_buffer: PackedByteArray = _encode_value(args_buffer.size(), PacketDataType.UINT8)
	var timestamp_buffer: PackedByteArray = _encode_value(get_current_time(), PacketDataType.UINT32)
	var checksum: int = fletcher16(id_buffer + length_buffer + timestamp_buffer + args_buffer)
	output_buffer.append_array(id_buffer)
	output_buffer.append_array(length_buffer)
	output_buffer.append_array(timestamp_buffer)
	output_buffer.append_array(_encode_value(checksum, PacketDataType.UINT16))
	output_buffer.append_array(args_buffer)
	match parsed_ip[0]:
		AddressType.MONOCAST:
			if parsed_ip[1].length() == 0:
				return
			Comms.bcast_server.set_dest_address(parsed_ip[1], Comms.BCAST_PORT)
			Comms.bcast_server.put_packet(output_buffer)
		AddressType.MULTICAST:
			Comms.mcast_server.put_packet(output_buffer)
		AddressType.BROADCAST:
			Comms.bcast_server.set_dest_address(Comms.BCAST_IP, Comms.BCAST_PORT)
			Comms.bcast_server.put_packet(output_buffer)
		AddressType.LOCALHOST:
			Comms.bcast_server.set_dest_address(Comms.LOCALHOST_IP, Comms.BCAST_PORT)
			Comms.bcast_server.put_packet(output_buffer)

func make_float(value: float) -> Array:
	return [value, PacketDataType.FLOAT]

func make_uint8(value: int) -> Array:
	return [value, PacketDataType.UINT8]

func make_uint16(value: int) -> Array:
	return [value, PacketDataType.UINT16]

func make_uint32(value: int) -> Array:
	return [value, PacketDataType.UINT32]

func process_chat(data: PackedByteArray, addr: String) -> void:
	var msg: Variant = JSON.parse_string(data.get_string_from_utf8())
	Logger.chat("(%s) %s" % [msg["sender"], msg["message"]])

func launch(ipa_enabled: bool, nos_enabled: bool) -> void:
	Logger.info("Beginning launch sequence")
	if ipa_enabled:
		Logger.info("IPA enabled")
	if nos_enabled:
		Logger.info("NOS enabled")
	send_packet("bcast", LAUNCH_ID, [make_uint8(Config.config["mode"]), make_uint32(Config.config["burnTime"]), make_uint8(int(nos_enabled)), make_uint8(int(ipa_enabled))])

func abort(reason: AbortReason) -> void:
	Logger.warn("Emitting abort with reason %d: %s" % [reason, ABORT_DESCRIPTIONS[reason]])
	send_packet("bcast", ABORT_ID, [make_uint8(Config.config["mode"]), make_uint8(reason)])
