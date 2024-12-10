shader_type canvas_item;

uniform vec3 pressure_color: source_color;

const float BORDER_WIDTH = 2.0 / 10.0;

bool border(vec2 uv) {
	return uv.y < BORDER_WIDTH || uv.y > 1.0 - BORDER_WIDTH;
}

void fragment() {
	COLOR.rgb = border(UV) ? vec3(0.0) : pressure_color;
}
