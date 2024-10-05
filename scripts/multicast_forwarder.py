import socket
import struct

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 128)
sock.bind(("", 42080))
group = socket.inet_aton("224.0.0.3")
host = socket.inet_aton(socket.gethostbyname(socket.gethostname()))
# sock.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_IF, host)
mreq = struct.pack("4sL", group, socket.INADDR_ANY)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, group + host)
sock.setblocking(0)

sock_localhost = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
# sock_localhost.bind(("127.0.0.1", 42099))
sock_localhost.setblocking(0)

while True:
	try:
		data, addr = sock.recvfrom(1024)
		packet = len(addr[0]).to_bytes(1) + addr[0].encode() + data
		print(packet)
		sock_localhost.sendto(packet, ("127.0.0.1", 42099))
	except Exception as e:
		# print(e)
		pass