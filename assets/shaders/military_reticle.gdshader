shader_type canvas_item;

uniform bool is_locked = false;
uniform vec4 search_color : source_color = vec4(0.0, 0.9, 0.85, 0.75);
uniform vec4 locked_color : source_color = vec4(1.0, 0.25, 0.15, 1.0);
uniform float corner_size : hint_range(0.05, 0.45) = 0.22;
uniform float thickness : hint_range(0.005, 0.05) = 0.012;
uniform float circle_radius : hint_range(0.2, 0.48) = 0.36;

void fragment() {
	vec2 uv = UV;
	vec2 delta = uv - vec2(0.5);
	float dist = length(delta);
	
	bool is_circle = false;
	bool is_ticks = false;
	bool is_ladders = false;
	bool is_inner_bracket = false;
	bool is_center_dot = false;
	
	// 1. Circulo externo da reticula tatica (permanece ciano com brilho sutil)
	if (abs(dist - circle_radius) < thickness) {
		is_circle = true;
	}
	
	// 2. Traços de mira cruzada externos (N, S, L, O)
	float tick_thickness = thickness * 0.9;
	if (abs(delta.x) < tick_thickness) {
		if ((delta.y < -circle_radius && delta.y > -0.48) || (delta.y > circle_radius && delta.y < 0.48)) {
			is_ticks = true;
		}
	}
	if (abs(delta.y) < tick_thickness) {
		if ((delta.x < -circle_radius && delta.x > -0.48) || (delta.x > circle_radius && delta.x < 0.48)) {
			is_ticks = true;
		}
	}
	
	// 3. Réguas graduadas de elevação nos eixos horizontais
	if (abs(delta.y) < 0.06) {
		float abs_x = abs(delta.x);
		if (abs_x > 0.40 && abs_x < 0.47) {
			float ladder_step = fract(abs_x * 40.0);
			if (ladder_step < 0.35 && abs(delta.y) < 0.035) {
				is_ladders = true;
			}
		}
	}
	
	// 4. Colchetes angulares internos de enquadramento
	vec2 c = abs(delta) * 2.0;
	bool in_inner_x = (c.x > 0.14 && c.x < 0.26);
	bool in_inner_y = (c.y > 0.14 && c.y < 0.26);
	bool inner_edge_x = abs(c.x - 0.26) < 0.025;
	bool inner_edge_y = abs(c.y - 0.26) < 0.025;
	if ((in_inner_x && inner_edge_y) || (in_inner_y && inner_edge_x)) {
		is_inner_bracket = true;
	}
	
	// 5. Ponto de visada central
	if (dist < 0.016) {
		is_center_dot = true;
	}
	
	if (is_circle || is_ticks || is_ladders) {
		COLOR = search_color;
	} else if (is_inner_bracket || is_center_dot) {
		COLOR = is_locked ? locked_color : search_color;
	} else {
		COLOR = vec4(0.0);
	}
}
