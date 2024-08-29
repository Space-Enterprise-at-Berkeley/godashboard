extends Node
class_name Camera

signal frame(image: Image)
signal camera_connect

static var cameras_registry: Dictionary = {}
static var cameras_id_lookup: Dictionary = {}

var camera_name: String
var uri: String
var camera_connected: bool = false
var thread: Thread
var ip: String

static func register_camera(id: int, camera_name_p: String, ip_p: String) -> Camera:
	var camera: Camera = Camera.new(camera_name_p, ip_p)
	cameras_registry[camera_name_p] = camera
	cameras_id_lookup[id] = camera_name_p
	return camera

func _init(name_p: String, ip_p: String) -> void:
	camera_name = name_p
	ip = ip_p
	uri = "rtsp://admin:seberkeley123@%s:554/cam/realmonitor?channel=1&subtype=0" % ip
	#uri = "http://47.51.131.147/-wvhttp-01-/GetOneShot?image_size=1280x720&frame_count=1000000000"

func connect_camera() -> bool:
	thread = Thread.new()
	thread.start(_spawn_rtsp_process)
	camera_connected = true
	camera_connect.emit()
	Logger.info("Camera %s connected" % camera_name)
	return true

func process_frame(data: PackedByteArray) -> void:
	if not camera_connected:
		return
	if data.size() > 0:
		var image: Image = Image.new()
		print_debug(image.load_jpg_from_buffer(data))
		frame.emit(image)

func _spawn_rtsp_process() -> void:
	return
	OS.execute("py", [ProjectSettings.globalize_path("res://scripts/rtsp.py")])
