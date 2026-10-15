shader_type spatial;
render_mode specular_disabled;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float x = abs(world_position.x - sin(world_position.z * 0.22)*0.75);
 float trail = 1.0-smoothstep(0.7,1.3,x);
 float camp = 1.0-smoothstep(2.1,3.3,length(world_position.xz));
 float patches = sin(world_position.x * 0.67)*sin(world_position.z*0.53);
 vec3 grass = mix(vec3(0.20,0.43,0.30),vec3(0.36,0.60,0.35),smoothstep(-0.4,0.4,patches));
 ALBEDO = mix(grass,vec3(0.68,0.48,0.29),max(trail,camp));
 ROUGHNESS=1.0;
}
void light() {
 float band=dot(NORMAL,LIGHT)>0.3 ? 1.0 : 0.65;
 DIFFUSE_LIGHT+=ALBEDO*band*LIGHT_COLOR*ATTENUATION/PI;
}
