shader_type canvas_item;

void fragment() {
	if (COLOR.rgb == vec3(1.0)) {
		COLOR.rgb = vec3(0.0, 1.0, 0.0);
	}
}
