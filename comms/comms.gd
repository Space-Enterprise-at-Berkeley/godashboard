extends Node

const MCAST_PORT: int = 42080
const MCAST_IP: String = "224.0.0.3"
const BCAST_PORT: int = 42099
const BCAST_IP: String = "10.0.0.255"
const LOCALHOST_IP: String = "127.0.0.1"
const CAMERA_PORT: int = 42081
const CAMERA_PACKET_RESET_SIZE = 69

var mcast_server: PacketPeerUDP = PacketPeerUDP.new()
var bcast_server: PacketPeerUDP = PacketPeerUDP.new()
#var camera_server: PacketPeerUDP = PacketPeerUDP.new()

#var camera_ready: bool = false
#var camera_data: PackedByteArray
#var packet_count: int = 0

func _ready() -> void:
	mcast_server.bind(MCAST_PORT)
	bcast_server.bind(BCAST_PORT)
	bcast_server.set_broadcast_enabled(true)
	#camera_server.bind(CAMERA_PORT, "*", 1048576)
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
	#while camera_server.get_available_packet_count() > 0:
		#var data: PackedByteArray = camera_server.get_packet()
		#print(data.decode_u8(0))
		#if data.size() == CAMERA_PACKET_RESET_SIZE:
			#print(data)
			#if camera_ready:
				#_update_camera()
			#camera_ready = true
			#camera_data = PackedByteArray()
		#elif camera_ready:
			#packet_count += 1
			#camera_data.append_array(data)
			#print(camera_data.size())

func _update_camera() -> void:
	#print(camera_data.size())
	pass

func _await_multicast() -> void:
	while true:
		var enet_interfaces: Array[Dictionary] = IP.get_local_interfaces().filter(func (i: Dictionary) -> bool: return i["addresses"].any(func (s: String) -> bool: return s.begins_with("10.0.0.")))
		if enet_interfaces.size() > 0:
			mcast_server.join_multicast_group(MCAST_IP, enet_interfaces[0]["name"])
			return
		await get_tree().create_timer(1).timeout
