extends Node

const MCAST_PORT: int = 42080
const MCAST_IP: String = "224.0.0.3"
const BCAST_PORT: int = 42099
var mcast_server: PacketPeerUDP = PacketPeerUDP.new()
var bcast_server: PacketPeerUDP = PacketPeerUDP.new()

func _ready() -> void:
	mcast_server.bind(MCAST_PORT)
	bcast_server.bind(BCAST_PORT)
	bcast_server.set_broadcast_enabled(true)
	_await_multicast()

func _process(delta: float) -> void:
	while mcast_server.get_available_packet_count() > 0:
		var data: PackedByteArray = mcast_server.get_packet()
		var addr: String = mcast_server.get_packet_ip()
		Databus.process_packet(data, addr)
	while bcast_server.get_available_packet_count() > 0:
		var data: PackedByteArray = mcast_server.get_packet()
		var addr: String = mcast_server.get_packet_ip()
		Databus.process_packet(data, addr)

func _await_multicast() -> void:
	while true:
		var enet_interfaces: Array[Dictionary] = IP.get_local_interfaces().filter(func (i: Dictionary) -> bool: return i["addresses"].any(func (s: String) -> bool: return s.begins_with("10.0.0.")))
		if enet_interfaces.size() > 0:
			mcast_server.join_multicast_group("224.0.0.3", enet_interfaces[0]["name"])
			return
		await get_tree().create_timer(1).timeout
