shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 ember_color : source_color = vec4(1.0, 0.31, 0.065, 1.0);
uniform float motion = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float y = 1.0 - UV.y;
	float t = TIME * motion;
	float flow = noise(vec2(UV.x * 5.0, y * 5.0 - t * 2.8));
	float fine = noise(vec2(UV.x * 13.0, y * 11.0 - t * 4.2));
	float width = (1.0 - y) * 0.50 + 0.05;
	float x = abs(UV.x - 0.5 + (flow - 0.5) * y * 0.24);
	float edge = 1.0 - smoothstep(width * 0.3, width, x);
	float tip = 1.0 - smoothstep(0.47 + flow * 0.4, 0.98, y);
	float alpha = edge * tip * (0.35 + fine * 0.55) * smoothstep(0.0, 0.09, y);
	vec3 hot = mix(vec3(1.0, 0.63, 0.17), ember_color.rgb, smoothstep(0.10, 0.8, y));
	ALBEDO = hot;
	EMISSION = hot * 0.35;
	ALPHA = alpha * 0.38;
}
