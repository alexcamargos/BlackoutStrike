shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.02, 0.07, 0.14, 0.82);
uniform vec4 border_color : source_color = vec4(0.0, 0.9, 0.85, 0.9);
uniform float border_width : hint_range(0.005, 0.08) = 0.02;
uniform float corner_cut : hint_range(0.0, 0.3) = 0.12;
uniform bool cut_top_right = true;
uniform bool cut_bottom_left = true;
uniform bool cut_top_left = false;
uniform bool cut_bottom_right = false;

void fragment() {
	vec2 uv = UV;
	
	// Checagem dos cantos chanfrados a 45 graus
	bool outside = false;
	
	if (cut_top_right && (uv.x + (1.0 - uv.y)) > (2.0 - corner_cut)) {
		outside = true;
	}
	if (cut_bottom_left && ((1.0 - uv.x) + uv.y) > (2.0 - corner_cut)) {
		outside = true;
	}
	if (cut_top_left && ((1.0 - uv.x) + (1.0 - uv.y)) > (2.0 - corner_cut)) {
		outside = true;
	}
	if (cut_bottom_right && (uv.x + uv.y) > (2.0 - corner_cut)) {
		outside = true;
	}
	
	if (outside) {
		COLOR = vec4(0.0);
	} else {
		// Distancia ate as bordas
		float dist_x = min(uv.x, 1.0 - uv.x);
		float dist_y = min(uv.y, 1.0 - uv.y);
		float edge_dist = min(dist_x, dist_y);
		
		// Distancia ate as diagonais chanfradas
		if (cut_top_right) {
			float d = (2.0 - corner_cut) - (uv.x + (1.0 - uv.y));
			edge_dist = min(edge_dist, d * 0.7071);
		}
		if (cut_bottom_left) {
			float d = (2.0 - corner_cut) - ((1.0 - uv.x) + uv.y);
			edge_dist = min(edge_dist, d * 0.7071);
		}
		if (cut_top_left) {
			float d = (2.0 - corner_cut) - ((1.0 - uv.x) + (1.0 - uv.y));
			edge_dist = min(edge_dist, d * 0.7071);
		}
		if (cut_bottom_right) {
			float d = (2.0 - corner_cut) - (uv.x + uv.y);
			edge_dist = min(edge_dist, d * 0.7071);
		}
		
		if (edge_dist < border_width) {
			float glow = 1.0 + 0.3 * (1.0 - edge_dist / border_width);
			COLOR = border_color * glow;
		} else {
			COLOR = bg_color;
		}
	}
}
