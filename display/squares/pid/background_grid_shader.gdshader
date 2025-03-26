shader_type canvas_item;

uniform float height = 128.0;
uniform float width = 128.0;
uniform float grid_lines_h = 4.0;
uniform float grid_lines_w = 6.0;

const float LINE_THICKNESS = 2.0;

void fragment() {
	COLOR.rgb = vec3(0.0);

	float h_line_thickness = LINE_THICKNESS / height;
	float h_offset = h_line_thickness / 2.0;
	bool grid_h = (mod(UV.y + h_offset, 1.0 / grid_lines_h) * grid_lines_h) < h_line_thickness * grid_lines_h;

	float w_line_thickness = LINE_THICKNESS / width;
	float w_offset = w_line_thickness / 2.0;
	bool grid_w = (mod(UV.x + w_offset, 1.0 / grid_lines_w) * grid_lines_w) < w_line_thickness * grid_lines_w;

	COLOR.a = float(grid_h || grid_w);
}
