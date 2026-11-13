shader_type canvas_item;

uniform vec4 cyan_color : source_color = vec4(0.196, 0.839, 1.0, 0.95);
uniform float heading_offset : hint_range(-10.0, 10.0) = 0.0;
uniform float thickness : hint_range(0.005, 0.04) = 0.015;

void fragment() {
	vec2 uv = UV;
	bool draw = false;

	// 1. Indicador central triangular superior (▼)
	vec2 tri_top = uv - vec2(0.5, 0.06);
	if (tri_top.y > 0.0 && tri_top.y < 0.22) {
		if (abs(tri_top.x) < (0.22 - tri_top.y) * 0.14) {
			draw = true;
		}
	}

	// 2. Indicador central triangular inferior (▲)
	vec2 tri_bot = vec2(0.5, 0.94) - uv;
	if (tri_bot.y > 0.0 && tri_bot.y < 0.22) {
		if (abs(tri_bot.x) < (0.22 - tri_bot.y) * 0.14) {
			draw = true;
		}
	}

	// 3. Fita horizontal graduada de azimute com tiques verticais
	if (uv.y > 0.30 && uv.y < 0.70 && uv.x > 0.16 && uv.x < 0.84) {
		float tape_x = uv.x + heading_offset * 0.05;
		float tick = fract(tape_x * 28.0);
		float major_step = fract(tape_x * 7.0);
		bool is_major = (major_step < 0.08);

		if (tick < 0.07) {
			if (is_major && uv.y > 0.30 && uv.y < 0.70) {
				draw = true;
			} else if (uv.y > 0.42 && uv.y < 0.62) {
				draw = true;
			}
		}
	}

	// 4. Marcadores em losango vazado (◇) nas laterais
	vec2 left_diamond = abs(uv - vec2(0.09, 0.50));
	float ld_dist = left_diamond.x * 0.22 + left_diamond.y;
	if (abs(ld_dist - 0.18) < 0.035) {
		draw = true;
	}
	vec2 right_diamond = abs(uv - vec2(0.91, 0.50));
	float rd_dist = right_diamond.x * 0.22 + right_diamond.y;
	if (abs(rd_dist - 0.18) < 0.035) {
		draw = true;
	}

	if (draw) {
		COLOR = cyan_color;
	} else {
		COLOR = vec4(0.0);
	}
}
