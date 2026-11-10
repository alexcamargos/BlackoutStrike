shader_type canvas_item;

uniform vec4 lock_color : source_color = vec4(1.0, 0.25, 0.15, 1.0);
uniform float corner_len : hint_range(0.1, 0.5) = 0.32;
uniform float thickness : hint_range(0.01, 0.08) = 0.04;
uniform float pulse_speed : hint_range(1.0, 10.0) = 4.0;

void fragment() {
	vec2 uv = UV;
	bool draw = false;
	
	// Efeito de pulso sutil militar
	float pulse = 0.88 + 0.12 * sin(TIME * pulse_speed);
	
	// 1. Losango indicador (◆) acima da caixa de mira (em y de 0.0 a 0.22)
	vec2 diamond_p = abs(uv - vec2(0.5, 0.11));
	if ((diamond_p.x + diamond_p.y * 1.2) < 0.08) {
		draw = true;
	}
	
	// 2. Colchetes angulares [   ] da caixa do alvo (em y de 0.25 a 0.95)
	vec2 box_uv = vec2(uv.x, (uv.y - 0.25) / 0.70);
	if (box_uv.y >= 0.0 && box_uv.y <= 1.0) {
		vec2 c = abs(box_uv - vec2(0.5)) * 2.0; // 0.0 no centro, 1.0 nas bordas
		
		bool on_border_x = (c.x > (1.0 - thickness));
		bool on_border_y = (c.y > (1.0 - thickness * 1.4));
		
		bool in_corner_x = (c.x > (1.0 - corner_len));
		bool in_corner_y = (c.y > (1.0 - corner_len));
		
		if ((on_border_x && in_corner_y) || (on_border_y && in_corner_x)) {
			draw = true;
		}
	}
	
	if (draw) {
		COLOR = lock_color * pulse;
	} else {
		COLOR = vec4(0.0);
	}
}
