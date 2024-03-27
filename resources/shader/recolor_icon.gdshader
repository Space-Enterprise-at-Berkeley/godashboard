shader_type canvas_item;

uniform vec3 color: source_color;

void fragment() {
	if (COLOR.rgb == vec3(0.0, 0.0, 0.0)) {
		COLOR.rgb = color;
	}
}