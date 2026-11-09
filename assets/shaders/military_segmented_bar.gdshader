shader_type canvas_item;

uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform int segment_count : hint_range(1, 50) = 20;
uniform float segment_gap : hint_range(0.0, 0.5) = 0.15;
uniform float slant : hint_range(-1.0, 1.0) = 0.25;
uniform vec4 active_color : source_color = vec4(0.0, 0.9, 0.85, 1.0);
uniform vec4 warning_color : source_color = vec4(1.0, 0.3, 0.2, 1.0);
uniform vec4 background_color : source_color = vec4(0.06, 0.1, 0.16, 0.8);
uniform vec4 border_color : source_color = vec4(0.15, 0.35, 0.5, 0.9);
uniform float warning_threshold : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec2 uv = UV;
	float slanted_x = uv.x - (uv.y - 0.5) * slant;
	
	if (slanted_x < 0.0 || slanted_x > 1.0) {
		COLOR = vec4(0.0);
	} else {
		// Borda exterior do painel com recortes
		float border = 0.0;
		if (uv.y < 0.08 || uv.y > 0.92 || uv.x < 0.015 || uv.x > 0.985) {
			border = 1.0;
		}
		
		float total_slots = float(segment_count);
		float scaled_x = slanted_x * total_slots;
		float segment_index = floor(scaled_x);
		float segment_fraction = fract(scaled_x);
		
		bool is_gap = (segment_fraction < segment_gap) && (segment_index > 0.0) && (segment_index < total_slots);
		
		float normalized_pos = (segment_index + 0.5) / total_slots;
		bool is_filled = normalized_pos <= fill_ratio;
		
		vec4 current_color = active_color;
		if (fill_ratio <= warning_threshold) {
			current_color = warning_color;
		}
		
		vec4 final_color = background_color;
		if (is_filled && !is_gap) {
			float vert_glow = 0.85 + 0.3 * (1.0 - uv.y);
			final_color = current_color * vert_glow;
		} else if (is_gap) {
			final_color = background_color * 0.5;
		}
		
		if (border > 0.5) {
			final_color = mix(final_color, border_color, 0.8);
		}
		
		COLOR = final_color;
	}
}
