import cv2
import socket
import sys

# if "rtsp.py" not in sys.argv[0]:
# 	exit()

port = int(sys.argv[-1])

# cap = cv2.VideoCapture("http://47.51.131.147/-wvhttp-01-/GetOneShot?image_size=1280x720&frame_count=1000000000")
cap = cv2.VideoCapture("rtsp://admin:seberkeley123@10.0.0.%d:554/cam/realmonitor?channel=1&subtype=0" % port)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

while cap.isOpened():
	ret, frame = cap.read()
	frame = cv2.resize(frame, (400, 300))
	encode, buffer = cv2.imencode(".jpg", frame, [int(cv2.IMWRITE_JPEG_QUALITY), 80])
	buffer = port.to_bytes(1, "little") + bytes(buffer)
	print(len(buffer))
	if len(buffer) <= 65507:
		sock.sendto(buffer, ("127.0.0.1", 42081))
	else:
		print("Frame size: %d" % len(buffer))
	cv2.waitKey(100)

cap.release()