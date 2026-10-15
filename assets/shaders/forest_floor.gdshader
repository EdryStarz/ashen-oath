shader_type spatial;
uniform sampler2D earth_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 uv = world_position.xz * 0.5;
 vec3 earth = texture(earth_color, uv).rgb;
 float bend = sin(world_position.z * 0.22) * 0.75;
 float edge = abs(world_position.x - bend);
 float clearing = 1.0 - smoothstep(2.1, 3.7, length(world_position.xz));
 float trail = 1.0 - smoothstep(0.7, 1.5, edge + (earth.r - 0.5) * 0.65);
 float dirt = max(trail, clearing);
 ALBEDO = mix(earth * vec3(0.39, 0.48, 0.29), earth * vec3(0.78, 0.70, 0.57), dirt);
 NORMAL_MAP = texture(earth_normal, uv).rgb;
 NORMAL_MAP_DEPTH = 0.45;
 ROUGHNESS = 0.95;
}
