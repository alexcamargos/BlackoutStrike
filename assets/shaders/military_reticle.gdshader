shader_type canvas_item;

uniform bool is_locked = false;
uniform vec4 search_color : source_color = vec4(0.196, 0.839, 1.0, 0.85);
uniform vec4 locked_color : source_color = vec4(0.851, 0.220, 0.118, 1.0);
uniform float corner_size : hint_range(0.05, 0.45) = 0.22;
uniform float thickness : hint_range(0.005, 0.05) = 0.010;
uniform float circle_radius : hint_range(0.2, 0.48) = 0.34;

void fragment() {
	vec2 uv = UV;
	vec2 delta = uv - vec2(0.5);
	float dist = length(delta);

	bool is_circle = false;
	bool is_ticks = false;
	bool is_ladders = false;
	bool is_outer_bracket = false;
	bool is_center_dot = false;

	// 1. Circulo externo da reticula tatica com aberturas nos 4 eixos cardeais
	bool in_cardinal_gap = (abs(delta.x) < 0.035 || abs(delta.y) < 0.035);
	if (abs(dist - circle_radius) < thickness && !in_cardinal_gap) {
		is_circle = true;
	}

	// 2. Cruzamentos N, S, L, O atravessando a borda do circulo (estilo VC-06)
	float tick_thickness = thickness * 0.75;
	if (abs(delta.x) < tick_thickness) {
		if ((delta.y < -(circle_radius - 0.05) && delta.y > -(circle_radius + 0.06)) ||
			(delta.y > (circle_radius - 0.05) && delta.y < (circle_radius + 0.06))) {
			is_ticks = true;
		}
	}
	if (abs(delta.y) < tick_thickness) {
		if ((delta.x < -(circle_radius - 0.05) && delta.x > -(circle_radius + 0.06)) ||
			(delta.x > (circle_radius - 0.05) && delta.x < (circle_radius + 0.06))) {
			is_ticks = true;
		}
	}

	// 3. Reguas graduadas de elevacao nos eixos horizontais internos (estilo VC-06)
	if (abs(delta.y) < 0.055) {
		float abs_x = abs(delta.x);
		if (abs_x > 0.22 && abs_x < 0.34) {
			float ladder_step = fract(abs_x * 42.0);
			if (ladder_step < 0.28 && abs(delta.y) < 0.035) {
				is_ladders = true;
			}
			if (abs(delta.y) < tick_thickness * 0.8) {
				is_ladders = true;
			}
		}
	}

	// 4. Colchetes angulares externos de enquadramento (┌ ┐ └ ┘) conforme VC-06
	vec2 oc = abs(delta) * 2.0;
	bool in_outer_x = (oc.x > 0.74 && oc.x < 0.90);
	bool in_outer_y = (oc.y > 0.74 && oc.y < 0.90);
	bool outer_edge_x = abs(oc.x - 0.90) < 0.012;
	bool outer_edge_y = abs(oc.y - 0.90) < 0.012;
	if ((in_outer_x && outer_edge_y) || (in_outer_y && outer_edge_x)) {
		is_outer_bracket = true;
	}

	// 5. Ponto de visada central sutil
	if (dist < 0.012 && !is_locked) {
		is_center_dot = true;
	}

	if (is_circle || is_ticks || is_ladders) {
		COLOR = search_color;
	} else if (is_outer_bracket) {
		COLOR = vec4(search_color.rgb, search_color.a * 0.65);
	} else if (is_center_dot) {
		COLOR = search_color;
	} else {
		COLOR = vec4(0.0);
	}
}
