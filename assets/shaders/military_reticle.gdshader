shader_type canvas_item;

uniform bool is_locked = false;
uniform vec4 search_color : source_color = vec4(0.0, 0.9, 0.85, 0.75);
uniform vec4 locked_color : source_color = vec4(1.0, 0.25, 0.15, 1.0);
uniform float corner_size : hint_range(0.05, 0.45) = 0.22;
uniform float thickness : hint_range(0.01, 0.1) = 0.035;

void fragment() {
	vec2 uv = UV;
	vec2 c = abs(uv - 0.5) * 2.0;
	
	// Colchetes angulares de mira militar nos quatro cantos
	bool in_corner_x = (c.x > (1.0 - corner_size));
	bool in_corner_y = (c.y > (1.0 - corner_size));
	bool border_x = (c.x > (1.0 - thickness));
	bool border_y = (c.y > (1.0 - thickness));
	
	bool is_bracket = (in_corner_x && border_y) || (in_corner_y && border_x);
	
	// Ponto central de visada
	float center_dist = length(uv - 0.5);
	bool is_center_dot = (center_dist < 0.04);
	
	// Tiques de mira cruzada
	bool is_cross_tick = ((abs(uv.x - 0.5) < 0.015 && abs(uv.y - 0.5) > 0.12 && abs(uv.y - 0.5) < 0.28) ||
	                     (abs(uv.y - 0.5) < 0.015 && abs(uv.x - 0.5) > 0.12 && abs(uv.x - 0.5) < 0.28));
	
	if (is_bracket || is_center_dot || is_cross_tick) {
		vec4 col = is_locked ? locked_color : search_color;
		COLOR = col;
	} else {
		COLOR = vec4(0.0);
	}
}
