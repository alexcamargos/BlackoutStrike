shader_type canvas_item;

uniform vec4 cyan_color : source_color = vec4(0.0, 0.9, 0.85, 0.85);
uniform float heading_offset : hint_range(-10.0, 10.0) = 0.0;
uniform float thickness : hint_range(0.005, 0.04) = 0.015;

void fragment() {
	vec2 uv = UV;
	bool draw = false;
	
	// 1. Moldura trapezoidal superior (\_______/)
	// Linha horizontal central superior
	if (uv.y < 0.22 && uv.y > 0.16 && uv.x > 0.32 && uv.x < 0.68) {
		draw = true;
	}
	// Linhas inclinadas nas bordas do trapezio
	float left_diag = (uv.x - 0.22) * 1.5 - (0.22 - uv.y);
	if (abs(left_diag) < 0.025 && uv.x > 0.18 && uv.x < 0.33 && uv.y < 0.22) {
		draw = true;
	}
	float right_diag = (0.78 - uv.x) * 1.5 - (0.22 - uv.y);
	if (abs(right_diag) < 0.025 && uv.x > 0.67 && uv.x < 0.82 && uv.y < 0.22) {
		draw = true;
	}
	
	// 2. Indicador central triangular (▼)
	vec2 tri_p = uv - vec2(0.5, 0.32);
	if (tri_p.y > 0.0 && tri_p.y < 0.14) {
		if (abs(tri_p.x) < (0.14 - tri_p.y) * 0.7) {
			draw = true;
		}
	}
	
	// 3. Fita horizontal graduada de azimute com tiques verticais
	if (uv.y > 0.48 && uv.y < 0.78 && uv.x > 0.12 && uv.x < 0.88) {
		float tape_x = uv.x + heading_offset * 0.05;
		float tick = fract(tape_x * 24.0);
		// Tique longo a cada 3 divisoes
		float major_step = fract(tape_x * 8.0);
		bool is_major = (major_step < 0.08);
		
		if (tick < 0.06) {
			if (is_major && uv.y < 0.76) {
				draw = true;
			} else if (uv.y > 0.58 && uv.y < 0.72) {
				draw = true;
			}
		}
	}
	
	// 4. Marcadores em losango (◇) nas laterais
	vec2 left_diamond = abs(uv - vec2(0.14, 0.60));
	if (abs(left_diamond.x + left_diamond.y - 0.035) < 0.008) {
		draw = true;
	}
	vec2 right_diamond = abs(uv - vec2(0.86, 0.60));
	if (abs(right_diamond.x + right_diamond.y - 0.035) < 0.008) {
		draw = true;
	}
	
	if (draw) {
		COLOR = cyan_color;
	} else {
		COLOR = vec4(0.0);
	}
}
