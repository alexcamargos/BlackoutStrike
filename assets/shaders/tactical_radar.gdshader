shader_type canvas_item;

uniform vec4 background_color : source_color = vec4(0.015, 0.08, 0.22, 0.75);
uniform vec4 ring_color : source_color = vec4(0.0, 0.9, 0.85, 0.6);
uniform vec4 sweep_color : source_color = vec4(0.0, 0.9, 0.85, 0.35);
uniform float sweep_speed : hint_range(0.5, 5.0) = 1.8;
uniform float ring_thickness : hint_range(0.002, 0.02) = 0.006;

void fragment() {
	vec2 uv = UV;
	vec2 delta = uv - vec2(0.5);
	float dist = length(delta) * 2.0; // 0.0 no centro, 1.0 na borda do circulo
	
	if (dist > 1.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 base_col = background_color;
		
		// 1. Aneis concentricos de alcance
		bool is_ring = false;
		if (abs(dist - 0.33) < ring_thickness || abs(dist - 0.66) < ring_thickness || abs(dist - 0.98) < ring_thickness * 1.5) {
			is_ring = true;
		}
		
		// 2. Reticula e eixos ortogonais e diagonais
		bool is_axis = false;
		if (abs(delta.x) < 0.004 || abs(delta.y) < 0.004) {
			is_axis = true;
		}
		// Diagonais a 45 graus
		if (abs(abs(delta.x) - abs(delta.y)) < 0.004 && dist > 0.15) {
			is_axis = true;
		}
		
		// 3. Feixe rotativo de varredura radar com rastro angular
		float angle = atan(delta.y, delta.x); // [-PI, PI]
		float current_sweep = mod(TIME * sweep_speed, 6.2831853) - 3.14159265;
		float diff = mod(current_sweep - angle + 6.2831853, 6.2831853);
		
		float trail_width = 1.1; // radianos de rastro
		float sweep_val = 0.0;
		if (diff < trail_width) {
			sweep_val = (1.0 - diff / trail_width);
		}
		
		vec4 final_color = base_col;
		if (sweep_val > 0.0) {
			final_color = mix(final_color, sweep_color, sweep_val * 0.7);
		}
		if (is_ring || is_axis) {
			final_color = mix(final_color, ring_color, 0.85);
		}
		
		COLOR = final_color;
	}
}
