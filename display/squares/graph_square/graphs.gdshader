shader_type canvas_item;

uniform float width = 1.0;

float line(vec2 p1, vec2 p2, vec2 uv) {
	float dist = distance(p1, p2);
	float uvdist = distance(p1, uv);
	return 1.0 - floor(1.0 - (0.001 * width) + distance(mix(p1, p2, clamp(uvdist / dist, 0.0, 1.0)), uv));
}

void fragment() {
	COLOR.rgb = vec3(line(vec2(0.2, 0.1), vec2(0.5, 0.7), UV));
}
