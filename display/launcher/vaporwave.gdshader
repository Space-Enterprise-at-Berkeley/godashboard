shader_type canvas_item;
uniform float brightness : hint_range(0.001, 2.0) = 1.0;
uniform float anchor : hint_range(-1.0,0.0) = -0.5;
//The point where all the lines come from.
uniform float speed_scale = 1.0;
uniform float fov : hint_range(0.001, 1.0) = 0.2;
uniform float line_count = 1.0;
uniform vec4 background_color : source_color = vec4(0.0, 0.1, 0.2, 1.0);
uniform vec4 grid_color : source_color = vec4(1.0, 0.5, 1.0, 1.0);
uniform float rainbow_intensity : hint_range(0.0, 1.0) = 0.0;
vec3 hsv2rgb(vec3 c) {
vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
return c.z * mix(vec3(1.0), rgb, c.y);
}
float grid(vec2 uv, float batt) {
vec2 size = vec2(uv.y, uv.y * uv.y * 0.2) * 0.01* (batt + 0.05);
uv += vec2(0.0, TIME * speed_scale);
uv = abs(fract(uv) - 0.5);
vec2 lines = smoothstep(size, vec2(0.0), uv);
lines += smoothstep(size * 5.0, vec2(0.0), uv) * 0.4 * batt;
return lines.x + lines.y;
}
void fragment() {
vec2 uv = UV;
vec4 col = background_color;
uv.y = 3.0 / (abs(uv.y + fov) + 0.05);
uv.x += anchor;
uv.x *= uv.y * line_count;
float gridVal = grid(uv, brightness);
float hue = fract(UV.y + TIME * 0.1);
vec4 rainbow_col = vec4(hsv2rgb(vec3(hue, 1.0, 1.0)), 1.0);
vec4 final_grid_color = mix(grid_color, rainbow_col, rainbow_intensity);
col = mix(background_color, final_grid_color, gridVal);
COLOR = col;
}