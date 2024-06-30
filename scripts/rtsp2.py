import cv2
import numpy as np
import win32pipe
import win32file

while True:
	try:
		pipe = win32file.CreateFile("\\\\.\\pipe\\godashboard_cam_cam1", win32file.GENERIC_READ | win32file.GENERIC_WRITE, 0, None, win32file.OPEN_EXISTING, win32file.FILE_ATTRIBUTE_NORMAL, None)
		res = win32pipe.SetNamedPipeHandleState(pipe, win32pipe.PIPE_READMODE_MESSAGE, None, None)
		break
	except:
		pass

while True:
	err, data = win32file.ReadFile(pipe, 2 << 20)
	print(len(data))
	# buffer = np.fromstring(data, np.uint8)
	# frame = cv2.imdecode(buffer, cv2.IMREAD_COLOR)
	# print(frame)
	# cv2.imshow("test", frame)
	cv2.waitKey(10)