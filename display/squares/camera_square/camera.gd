extends Node
class_name Camera

signal frame(image: Image)
signal camera_connect

static var cameras_registry: Dictionary = {}

var camera_name: String
var uri: String
var pipe: NamedPipe
var camera_connected: bool = false
var thread: Thread
var ip: String

static func register_camera(camera_name_p: String, ip_p: String) -> Camera:
	var camera: Camera = Camera.new(camera_name_p, ip_p)
	cameras_registry[camera_name_p] = camera
	return camera

func _init(name_p: String, ip_p: String) -> void:
	camera_name = name_p
	ip = ip_p
	uri = "http://47.51.131.147/-wvhttp-01-/GetOneShot?image_size=1280x720&frame_count=1000000000"
	pipe = NamedPipe.new()

func connect_camera() -> bool:
	print(camera_name)
	pipe.create_buffer(1 << 20)
	thread = Thread.new()
	thread.start(_spawn_rtsp_process)
	var ret: bool
	print(1)
	await get_tree().create_timer(1).timeout # Avoid race conditions with trying to read before the pipe exists
	print(2)
	if OS.get_name() == "Windows":
		ret = pipe.init("\\\\.\\pipe\\godashboard_cam_%s" % camera_name)
	else:
		Logger.error("Unix systems not yet supported")
		ret = false
	if ret:
		camera_connected = true
		camera_connect.emit()
	return ret

func _process(delta: float) -> void:
	if not camera_connected:
		return
	var out: PackedByteArray = pipe.read()
	if out.size() > 0:
		var image: Image = Image.new()
		image.load_jpg_from_buffer(out)
		frame.emit(image)
		#var image_texture: ImageTexture = ImageTexture.create_from_image(image)
		#texture_rect.texture = image_texture

func _spawn_rtsp_process() -> void:
	OS.execute("py", [ProjectSettings.globalize_path("res://scripts/rtsp.py")])
