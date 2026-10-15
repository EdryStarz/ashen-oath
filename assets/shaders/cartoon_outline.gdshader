shader_type spatial;
render_mode cull_front, unshaded;
uniform vec4 ink : source_color = vec4(0.10,0.15,0.24,1.0);
void vertex() { VERTEX += NORMAL * 0.014 / max(length(MODEL_MATRIX[0].xyz),0.001); }
void fragment() { ALBEDO = ink.rgb; }
