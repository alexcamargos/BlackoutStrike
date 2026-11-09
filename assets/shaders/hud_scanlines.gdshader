shader_type canvas_item;

uniform float scanline_count : hint_range(10.0, 400.0) = 140.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float flicker_speed : hint_range(0.0, 50.0) = 15.0;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.65;
uniform vec4 tint_color : source_color = vec4(0.2, 0.9, 0.8, 1.0);

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	
	// Scanlines horizontais
	float scanline = sin(UV.y * scanline_count * 3.14159265);
	scanline = (scanline + 1.0) * 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);
	
	// Ruido e estatica procedural
	float noise = random(UV + vec2(TIME * flicker_speed, TIME * 23.14));
	
	// Vignette nos cantos
	vec2 centered_uv = (UV - 0.5) * 2.0;
	float dist = length(centered_uv);
	float vignette = clamp(1.0 - dist * vignette_strength * 0.5, 0.0, 1.0);
	
	// Composicao diegetica
	vec3 col = base_color.rgb * scanline * vignette;
	col += (noise - 0.5) * noise_intensity;
	col = mix(col, col * tint_color.rgb, 0.3);
	
	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), base_color.a);
}
