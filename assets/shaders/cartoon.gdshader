shader_type spatial;
render_mode specular_disabled;
uniform vec4 base_color : source_color = vec4(0.4,0.65,0.55,1.0);
uniform sampler2D detail_color : source_color, filter_linear_mipmap;
uniform bool use_detail = false;
uniform float cutout = 0.0;
void fragment() {
 vec4 col = use_detail ? texture(detail_color, UV) * base_color : base_color;
 if (col.a < cutout) discard;
 ALBEDO = use_detail ? floor(col.rgb * 6.0 + 0.5) / 6.0 : col.rgb;
 ROUGHNESS = 1.0;
}
void light() {
 float n = dot(NORMAL, LIGHT);
 float band = n > 0.55 ? 1.0 : (n > 0.0 ? 0.68 : 0.38);
 DIFFUSE_LIGHT += ALBEDO * band * LIGHT_COLOR * ATTENUATION / PI;
}
