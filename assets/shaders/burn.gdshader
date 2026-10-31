shader_type canvas_item;

uniform vec4 paper_color : source_color = vec4(1.0);
uniform vec4 ink_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float canvas_px = 576.0;   // the canvas's on-screen size
uniform float dot_px = 3.0;        // screen pixels per dither dot
uniform float ash_level = 1.0;     // below 1.0 leaves some paper dots showing in the ash

// 4x4 ordered dither: the order in which dots fill in
const float BAYER[16] = float[](0., 8., 2., 10., 12., 4., 14., 6., 3., 11., 1., 9., 15., 7., 13., 5.);

void fragment() {
	vec4 cell = texture(TEXTURE, UV);          // R = burn amount 0..1, G = 1 if ink
	if (cell.g > 0.5) {
		COLOR = ink_color;
	} else {
		ivec2 p = ivec2(floor(UV * canvas_px / dot_px)) % 4;
		float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
		COLOR = (cell.r * ash_level > threshold) ? ink_color : paper_color;
	}
}