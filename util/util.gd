extends RefCounted
class_name Util

static func parse_color(color: Array) -> Color:
	return Color(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0)
