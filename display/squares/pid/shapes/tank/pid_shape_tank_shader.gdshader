shader_type canvas_item;

uniform float fill_level: hint_range(0.0, 1.0);
uniform vec3 fill_color: source_color;
uniform vec3 empty_color: source_color;
uniform vec3 pressure_color: source_color;

const float Y_SCALE = 4.0;
const float BORDER_WIDTH = 2.0 / 40.0;
const float PRESSURE_WIDTH = 4.0 / 40.0;

bool border(float squared_distance, float width, vec2 uv) {
	return (squared_distance > (1.0 - width) * (1.0 - width) && squared_distance < 1.0)
		|| uv.x < width
		|| uv.x > (1.0 - width);
}

void fragment() {
	float xDist = UV.x - 0.5;
	float yDist = UV.y - 0.5;
	float squared_distance = xDist * xDist + Y_SCALE * yDist * yDist;
	COLOR.a = squared_distance < 1.0 ? 1.0 : 0.0;
	vec3 fill_texture = (1.0 - UV.y) < fill_level ? fill_color : empty_color;
	COLOR.rgb = border(squared_distance, PRESSURE_WIDTH, UV) ? pressure_color : fill_texture;
	COLOR.rgb = border(squared_distance, BORDER_WIDTH, UV) ? vec3(0.0) : COLOR.rgb;
}
