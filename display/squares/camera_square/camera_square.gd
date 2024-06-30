extends Control
class_name CameraSquare

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var camera_name: Label = $VBoxContainer/CameraName
@onready var camera_ip: Label = $VBoxContainer/CameraIP
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var margin_container: MarginContainer = $MarginContainer
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var camera_name_2: Label = $MarginContainer/MarginContainer/CameraName2
@onready var camera_ip_2: Label = $MarginContainer/MarginContainer/CameraIP2

var camera: Camera

func setup(config: Dictionary) -> void:
	camera = Camera.cameras_registry[config["camera"]]
	camera_name.text = camera.camera_name
	camera_ip.text = camera.ip
	camera_name_2.text = camera.camera_name
	camera_ip_2.text = camera.ip
	camera.frame.connect(_handle_frame)
	camera.camera_connect.connect(_camera_connect)
	connect_button.pressed.connect(camera.connect_camera)
	if camera.camera_connected:
		_camera_connect()

func _handle_frame(image: Image) -> void:
	if not is_visible_in_tree():
		return
	var image_texture: ImageTexture = ImageTexture.create_from_image(image)
	texture_rect.texture = image_texture

func _camera_connect() -> void:
	v_box_container.hide()
	margin_container.show()
