extends Window
class_name DisplayRoot

@onready var theme_node: Control = $CanvasLayer/Theme
@onready var tab_container: TabManager = $CanvasLayer/Theme/VBoxContainer/TabContainer

func update_theme(t: Theme) -> void:
	theme_node.theme = t

func add_tab(tab: String) -> void:
	tab_container.add_tab(tab)
