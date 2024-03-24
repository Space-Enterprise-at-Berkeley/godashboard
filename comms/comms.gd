extends Node

const mcast_port: int = 42080
const mcast_ip: String = "224.0.0.3"
var mcast_server: PacketPeerUDP = PacketPeerUDP.new()

func _ready() -> void:
	mcast_server.bind(42080)
	var enet: Dictionary = IP.get_local_interfaces().filter(func (i: Dictionary) -> bool: return i["addresses"].any(func (s: String) -> bool: return s.begins_with("10.0.0.")))[0]
	mcast_server.join_multicast_group("224.0.0.3", enet["name"])

func _process(delta: float) -> void:
	while mcast_server.get_available_packet_count() > 0:
		var data: PackedByteArray = mcast_server.get_packet()
		var addr: String = mcast_server.get_packet_ip()
		Databus.process_packet(data, addr)
