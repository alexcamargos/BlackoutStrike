shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Texturas PBR da praia
uniform sampler2D sand_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D sand_arm : hint_default_white, filter_linear_mipmap_anisotropic;

// Texturas PBR do plato e vegetacao
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D grass_arm : hint_default_white, filter_linear_mipmap_anisotropic;

// Texturas PBR das falesias e rochedos
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_arm : hint_default_white, filter_linear_mipmap_anisotropic;

// Parametros de escala de UV no espaco de mundo (metros)
uniform float uv_scale_sand : hint_range(0.005, 0.5) = 0.08;
uniform float uv_scale_grass : hint_range(0.005, 0.5) = 0.04;
uniform float uv_scale_rock : hint_range(0.005, 0.5) = 0.035;

// Parametros de transicao de relevo vertical
uniform float beach_height_max : hint_range(-1.0, 2.0) = 0.45;
uniform float grass_height_min : hint_range(0.0, 3.0) = 0.95;
uniform float slope_rock_threshold : hint_range(0.1, 0.9) = 0.38;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 w_pos = v_world_pos;
	vec3 w_norm = normalize(v_world_normal);

	// Amostragem triplanar para rochas de falesia sem deformacao em paredes verticais
	vec3 tri_weights = abs(w_norm);
	tri_weights = max(tri_weights - 0.2, vec3(0.0));
	tri_weights /= max(0.0001, tri_weights.x + tri_weights.y + tri_weights.z);

	vec4 rock_x = texture(rock_albedo, w_pos.zy * uv_scale_rock);
	vec4 rock_y = texture(rock_albedo, w_pos.xz * uv_scale_rock);
	vec4 rock_z = texture(rock_albedo, w_pos.xy * uv_scale_rock);
	vec4 rock_col = rock_x * tri_weights.x + rock_y * tri_weights.y + rock_z * tri_weights.z;

	vec3 r_norm_x = texture(rock_normal, w_pos.zy * uv_scale_rock).rgb * 2.0 - 1.0;
	vec3 r_norm_y = texture(rock_normal, w_pos.xz * uv_scale_rock).rgb * 2.0 - 1.0;
	vec3 r_norm_z = texture(rock_normal, w_pos.xy * uv_scale_rock).rgb * 2.0 - 1.0;
	vec3 rock_norm_blend = r_norm_x * tri_weights.x + r_norm_y * tri_weights.y + r_norm_z * tri_weights.z;

	vec3 r_arm_x = texture(rock_arm, w_pos.zy * uv_scale_rock).rgb;
	vec3 r_arm_y = texture(rock_arm, w_pos.xz * uv_scale_rock).rgb;
	vec3 r_arm_z = texture(rock_arm, w_pos.xy * uv_scale_rock).rgb;
	vec3 rock_arm_blend = r_arm_x * tri_weights.x + r_arm_y * tri_weights.y + r_arm_z * tri_weights.z;

	// Amostragem de areia e grama em superficies horizontais
	vec4 sand_col = texture(sand_albedo, w_pos.xz * uv_scale_sand);
	vec3 sand_norm_map = texture(sand_normal, w_pos.xz * uv_scale_sand).rgb * 2.0 - 1.0;
	vec3 sand_arm_map = texture(sand_arm, w_pos.xz * uv_scale_sand).rgb;

	vec4 grass_col = texture(grass_albedo, w_pos.xz * uv_scale_grass);
	vec3 grass_norm_map = texture(grass_normal, w_pos.xz * uv_scale_grass).rgb * 2.0 - 1.0;
	vec3 grass_arm_map = texture(grass_arm, w_pos.xz * uv_scale_grass).rgb;

	// Mistura por altitude da areia litoranea para a grama
	float height_blend = smoothstep(beach_height_max, grass_height_min, w_pos.y);
	vec4 flat_col = mix(sand_col, grass_col, height_blend);
	vec3 flat_norm = mix(sand_norm_map, grass_norm_map, height_blend);
	vec3 flat_arm = mix(sand_arm_map, grass_arm_map, height_blend);

	// Mistura por declividade (inclinacao em relacao ao vetor vertical Y)
	float slope = 1.0 - clamp(abs(w_norm.y), 0.0, 1.0);
	float rock_factor = smoothstep(slope_rock_threshold - 0.12, slope_rock_threshold + 0.12, slope);

	vec4 final_albedo = mix(flat_col, rock_col, rock_factor);
	vec3 final_norm = normalize(mix(flat_norm, rock_norm_blend, rock_factor));
	vec3 final_arm = mix(flat_arm, rock_arm_blend, rock_factor);

	ALBEDO = final_albedo.rgb;
	AO = final_arm.r;
	ROUGHNESS = clamp(final_arm.g, 0.25, 0.95);
	METALLIC = final_arm.b * 0.15;
	SPECULAR = 0.2;
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(final_norm, 0.0)).xyz, 0.75));
}
