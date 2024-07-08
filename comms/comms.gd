extends Node

const MCAST_PORT: int = 42080
const MCAST_IP: String = "224.0.0.3"
const BCAST_PORT: int = 42099
const BCAST_IP: String = "10.0.0.255"
const LOCALHOST_IP: String = "127.0.0.1"
const CHAT_PORT: int = 42098
const CAMERA_PORT: int = 42081
const CAMERA_PACKET_RESET_SIZE = 69

var mcast_server: PacketPeerUDP = PacketPeerUDP.new()
var bcast_server: PacketPeerUDP = PacketPeerUDP.new()
var chat_server: PacketPeerUDP = PacketPeerUDP.new()
var cameras: Dictionary = {}

func _ready() -> void:
	mcast_server.bind(MCAST_PORT)
	bcast_server.bind(BCAST_PORT)
	bcast_server.set_broadcast_enabled(true)
	chat_server.bind(CHAT_PORT)
	chat_server.set_broadcast_enabled(true)
	chat_server.set_dest_address(BCAST_IP, CHAT_PORT)
	_await_multicast()

func _process(delta: float) -> void:
	while mcast_server.get_available_packet_count() > 0:
		var data: PackedByteArray = mcast_server.get_packet()
		var addr: String = mcast_server.get_packet_ip()
		Databus.process_packet(data, addr)
	while bcast_server.get_available_packet_count() > 0:
		var data: PackedByteArray = bcast_server.get_packet()
		var addr: String = bcast_server.get_packet_ip()
		Databus.process_packet(data, addr)
	while chat_server.get_available_packet_count() > 0:
		var data: PackedByteArray = chat_server.get_packet()
		var addr: String = chat_server.get_packet_ip()
		Databus.process_chat(data, addr)

func _await_multicast() -> void:
	while true:
		var enet_interfaces: Array[Dictionary] = IP.get_local_interfaces().filter(func (i: Dictionary) -> bool: return i["addresses"].any(func (s: String) -> bool: return s.begins_with("10.0.0.")))
		if enet_interfaces.size() > 0:
			mcast_server.join_multicast_group(MCAST_IP, enet_interfaces[0]["name"])
			return
		await get_tree().create_timer(1).timeout
