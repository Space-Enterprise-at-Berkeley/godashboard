shader_type canvas_item;

const int POINT_LENGTH = 100;

uniform vec2 points[POINT_LENGTH];

float line(vec2 p1, vec2 p2, float width, vec2 uv) {
	float dist = distance(p1, p2);
	float uvdist = distance(p1, uv);
	return 1.0 - floor(1.0 - (0.001 * width) + distance(mix(p1, p2, clamp(uvdist / dist, 0.0, 1.0)), uv));
}

void fragment() {
	COLOR.a = 0.0;
	float width = min(TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y) * 10.0;
	COLOR = vec4(line(vec2(0.2, 0.1), vec2(0.5, 0.7), width, UV));
	COLOR += vec4(line(vec2(0.4, 0.1), vec2(0.5, 0.8), width, UV));
	COLOR.rgb *= vec3(1.0, 1.0, 1.0);
}
