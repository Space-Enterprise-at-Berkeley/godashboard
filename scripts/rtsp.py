import cv2
import os

cap = cv2.VideoCapture("http://47.51.131.147/-wvhttp-01-/GetOneShot?image_size=1280x720&frame_count=1000000000")
# cap = cv2.VideoCapture("rtsp://admin:seberkeley123@10.0.0.205:554/cam/realmonitor?channel=1&subtype=0")

if os.name == "nt":
	import win32pipe
	import win32file

	pipe = win32pipe.CreateNamedPipe("\\\\.\\pipe\\godashboard_cam_testcam", win32pipe.PIPE_ACCESS_DUPLEX, win32pipe.PIPE_TYPE_MESSAGE | win32pipe.PIPE_READMODE_MESSAGE, 1, 2 << 20, 2 << 20, 0, None)

	win32pipe.ConnectNamedPipe(pipe, None)

	while cap.isOpened():
		ret, frame = cap.read()
		encode, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
		data = bytes(buffer)
		print(data[-3:])
		length_bytes = len(data).to_bytes(4, byteorder="little", signed=False)
		err, w = win32file.WriteFile(pipe, length_bytes + data)
		cv2.waitKey(100)

	cap.release()