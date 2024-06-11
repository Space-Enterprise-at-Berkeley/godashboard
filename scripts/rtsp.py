import socket
from multiprocessing import shared_memory
import cv2

cap = cv2.VideoCapture("http://47.51.131.147/-wvhttp-01-/GetOneShot?image_size=1280x720&frame_count=1000000000")
# cap = cv2.VideoCapture("rtsp://admin:seberkeley123@10.0.0.205:554/cam/realmonitor?channel=1&subtype=0")
# sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
# sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1048576)

# sock.connect(("127.0.0.1", 42081))

# new_frame_packet = bytes([0xff] * 69)

while cap.isOpened():
	ret, frame = cap.read()
	cv2.imshow("test", frame)
	# encode, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
	# sock.sendall(new_frame_packet)
	# data = bytes(buffer)
	# i = 0
	# while i < len(data):
	# 	sock.sendall(bytes([i // 4096]) + data[i:i + 4096])
	# 	i += 4096
	cv2.waitKey(100)

cap.release()
cv2.destroyAllWindows()