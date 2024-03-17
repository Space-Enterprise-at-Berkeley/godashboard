extends Node

const mcast_port: int = 42080
var mcast_server: PacketPeerUDP = PacketPeerUDP.new()

func _ready() -> void:
	mcast_server.bind(42080)

func _process(delta: float) -> void:
	#while true:
		#if mcast_server.get_available_packet_count() > 0:
			##mcast_server.get_packet().
			#pass
	pass
