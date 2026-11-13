shader_type canvas_item;

uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform int segment_count : hint_range(1, 50) = 10;
uniform float segment_gap : hint_range(0.0, 0.5) = 0.18;
uniform float slant : hint_range(-1.0, 1.0) = -0.32;
uniform vec4 active_color : source_color = vec4(0.196, 0.839, 1.0, 1.0);
uniform vec4 warning_color : source_color = vec4(0.851, 0.220, 0.118, 1.0);
uniform vec4 background_color : source_color = vec4(0.04, 0.10, 0.17, 0.78);
uniform vec4 border_color : source_color = vec4(0.196, 0.839, 1.0, 0.85);
uniform vec4 empty_segment_color : source_color = vec4(0.04, 0.10, 0.17, 0.55);
uniform vec4 empty_border_color : source_color = vec4(0.196, 0.839, 1.0, 0.45);
uniform float warning_threshold : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec2 uv = UV;
	
	// Recorte vertical para margem do painel
	if (uv.y < 0.05 || uv.y > 0.95) {
		COLOR = vec4(0.0);
	} else {
		// Aplicacao do cisalhamento angular (slant) militar
		float slanted_x = uv.x - (uv.y - 0.5) * slant;
		
		if (slanted_x < 0.0 || slanted_x > 1.0) {
			COLOR = vec4(0.0);
		} else {
			float total_slots = float(segment_count);
			float scaled_x = slanted_x * total_slots;
			float segment_index = floor(scaled_x);
			float segment_fract = fract(scaled_x);
			
			// Espacamento entre blocos segmentados
			bool is_gap = (segment_fract < segment_gap) && (segment_index > 0.0);
			if (is_gap) {
				COLOR = vec4(0.0);
			} else {
				// Coordenadas normalizadas dentro do bloco individual
				float inner_x = (segment_fract - (segment_index > 0.0 ? segment_gap : 0.0)) / (1.0 - (segment_index > 0.0 ? segment_gap : 0.0));
				bool is_block_border = (inner_x < 0.08 || inner_x > 0.92 || uv.y < 0.14 || uv.y > 0.86);
				
				float normalized_pos = (segment_index + 0.5) / total_slots;
				bool is_filled = (normalized_pos <= fill_ratio);
				
				vec4 current_color = active_color;
				if (fill_ratio <= warning_threshold) {
					current_color = warning_color;
				}
				
				if (is_filled) {
					float vert_glow = 0.88 + 0.35 * (1.0 - uv.y);
					vec4 filled_col = current_color * vert_glow;
					if (is_block_border) {
						filled_col = mix(filled_col, vec4(1.0, 1.0, 1.0, 1.0), 0.25);
					}
					COLOR = filled_col;
				} else {
					// Bloco vazio com contorno vazado de alta tecnologia militar
					if (is_block_border) {
						COLOR = empty_border_color;
					} else {
						COLOR = empty_segment_color;
					}
				}
			}
		}
	}
}
