extends Control
class_name LaunchButtonSquare

const SYSTEM_MODE_TEXTS: Dictionary = {
	"LAUNCH": "Launch",
	"HOTFIRE": "Burn",
	"COLDFLOW": "Flow",
	"COLDFLOW_WITH_IGNITER": "Flow (With Igniter)",
	"GASFLOW": "Gas Flow",
	"WATERFLOW": "Water Flow",
}

@onready var launch_button: Button = $VBoxContainer/LaunchMargin/LaunchButton
@onready var abort_button: Button = $VBoxContainer/AbortMargin/AbortButton

const BUTTON_ENABLE: String = "buttonΕnable"
const BUTTON_DISABLE: String = "buttonDisable"
const IPA_ENABLE: String = "ipaEnable"
const NOS_ENABLE: String = "nitrousEnable"

var ipa_enabled: bool = false
var nos_enabled: bool = false
var launch_enabled: bool = false

func _ready() -> void:
	launch_button.text = SYSTEM_MODE_TEXTS[Config.config["mode"]]
	launch_button.pressed.connect(_launch)
	abort_button.pressed.connect(_abort)
	Databus.register_callback(BUTTON_ENABLE, get_window(), _handle_packet_enable, true)
	Databus.register_callback(BUTTON_DISABLE, get_window(), _handle_packet_disable, true)

func _enable_launch() -> void:
	launch_enabled = true
	launch_button.disabled = false

func _disable_launch() -> void:
	launch_enabled = false
	launch_button.disabled = true

func _launch() -> void:
	if launch_enabled:
		Databus.launch(ipa_enabled, nos_enabled)

func _abort() -> void:
	Databus.abort("MANUAL")

func _handle_packet_enable(value: String, timestamp: int) -> void:
	var update: bool = false
	if value == IPA_ENABLE:
		ipa_enabled = true
		update = true
	if value == NOS_ENABLE:
		nos_enabled = true
		update = true
	if update:
		if ipa_enabled or nos_enabled:
			_enable_launch()
		else:
			_disable_launch()

func _handle_packet_disable(value: String, timestamp: int) -> void:
	var update: bool = false
	if value == IPA_ENABLE:
		ipa_enabled = false
		update = true
	if value == NOS_ENABLE:
		nos_enabled = false
		update = true
	if update:
		if ipa_enabled or nos_enabled:
			_enable_launch()
		else:
			_disable_launch()
