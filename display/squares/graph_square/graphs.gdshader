shader_type canvas_item;

const int POINT_LENGTH = 2000;
const float TIME_WIDTH = 30000.0;
const int STEP = 8;

uniform vec2 points[POINT_LENGTH];
uniform float timestamp;
uniform float max_y;
uniform float min_y;
uniform int start_index;
uniform vec3 color: source_color;

float line(vec2 p1, vec2 p2, float width, vec2 uv) {
	float dist = distance(p1, p2);
	float uvdist = distance(p1, uv);
	return 1.0 - floor(1.0 - (0.001 * width) + distance(mix(p1, p2, clamp(uvdist / dist, 0.0, 1.0)), uv));
}

void fragment() {
	COLOR.a = 0.0;
	float width = min(TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y) * 10.0;
	float y_height = max_y - min_y;
	float min_x = timestamp - TIME_WIDTH;
	for (int i = 0; i < POINT_LENGTH - STEP; i += STEP) {
		vec2 current_point = points[(i + start_index) % POINT_LENGTH];
		current_point.y = 1.0 - ((current_point.y - min_y) / y_height);
		current_point.x = (current_point.x - min_x) / TIME_WIDTH;
		vec2 next_point = points[(i + start_index + STEP) % POINT_LENGTH];
		next_point.y = 1.0 - ((next_point.y - min_y) / y_height);
		next_point.x = (next_point.x - min_x) / TIME_WIDTH;
		COLOR = max(COLOR, vec4(line(current_point, next_point, width, UV)) * step(-0.5, next_point.x));
	}
	COLOR.rgb *= color;
}
