shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.9, 0.85, 0.8);
uniform float pitch_offset : hint_range(-1.0, 1.0) = 0.0;
uniform float roll_angle : hint_range(-1.57, 1.57) = 0.0;
uniform float thickness : hint_range(0.003, 0.03) = 0.008;

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - vec2(0.5, 0.65);
	
	// Rotacao conforme o rolamento (roll) do helicoptero
	float cos_r = cos(roll_angle);
	float sin_r = sin(roll_angle);
	vec2 rotated_p = vec2(p.x * cos_r - p.y * sin_r, p.x * sin_r + p.y * cos_r);
	
	bool draw = false;
	
	// 1. Linha do horizonte com degraus e asas < >
	float horiz_y = rotated_p.y + pitch_offset * 0.15;
	if (abs(horiz_y) < thickness && abs(rotated_p.x) < 0.42 && abs(rotated_p.x) > 0.08) {
		draw = true;
	}
	
	// Pontas das asas: colchetes angulares < na esquerda e > na direita
	if (abs(rotated_p.x - 0.42) < 0.03 && abs(horiz_y) < 0.04) {
		if (abs(rotated_p.x - 0.42) + abs(horiz_y) * 1.5 < 0.04) {
			draw = true;
		}
	}
	if (abs(rotated_p.x + 0.42) < 0.03 && abs(horiz_y) < 0.04) {
		if (abs(rotated_p.x + 0.42) + abs(horiz_y) * 1.5 < 0.04) {
			draw = true;
		}
	}
	
	// Tiques verticais graduados ao longo da linha do horizonte
	if (abs(horiz_y) < 0.035 && abs(rotated_p.x) < 0.40 && abs(rotated_p.x) > 0.12) {
		float tick_step = fract(abs(rotated_p.x) * 18.0);
		if (tick_step < 0.18) {
			draw = true;
		}
	}
	
	// 2. Arco semicircular superior de arfagem (pitch arc)
	vec2 arc_p = uv - vec2(0.5, 0.65);
	float arc_r = length(arc_p);
	if (abs(arc_r - 0.38) < thickness && arc_p.y < 0.0) {
		draw = true;
	}
	// Tiques do arco
	if (abs(arc_r - 0.38) < 0.03 && arc_p.y < -0.05) {
		float arc_angle = atan(-arc_p.y, arc_p.x);
		float tick_arc = fract(arc_angle * 6.0);
		if (tick_arc < 0.15) {
			draw = true;
		}
	}
	
	if (draw) {
		COLOR = line_color;
	} else {
		COLOR = vec4(0.0);
	}
}
