shader_type canvas_item;
// Full-screen 1-bit fade: dots of ink_color fill in by a 4x4 ordered dither as coverage goes 0 -> 1.
// Keeps fades to two colours (an alpha fade would make greys).

uniform vec4 ink_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float coverage : hint_range(0.0, 1.0) = 1.0;
uniform vec2 size_px = vec2(1280.0, 720.0);   // the rect's size in game pixels
uniform float dot_px = 3.0;                    // game pixels per dither dot, same as the canvas

const float BAYER[16] = float[](0., 8., 2., 10., 12., 4., 14., 6., 3., 11., 1., 9., 15., 7., 13., 5.);

void fragment() {
	ivec2 p = ivec2(floor(UV * size_px / dot_px)) % 4;
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
	COLOR = coverage > threshold ? ink_color : vec4(0.0);
}
