shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.04, 0.10, 0.17, 0.78);
uniform vec4 border_color : source_color = vec4(0.196, 0.839, 1.0, 0.85);
uniform float border_width : hint_range(0.5, 4.0) = 1.5;
uniform float chamfer_size : hint_range(0.0, 32.0) = 14.0;
uniform vec2 panel_size = vec2(295.0, 48.0);

void fragment() {
	vec2 px = UV * panel_size;
	float w = panel_size.x;
	float h = panel_size.y;
	float c = chamfer_size;

	// Distancia assinada para poligono com chanfros de 45 graus
	// Chanfro superior esquerdo e inferior esquerdo / superior direito e inferior direito
	float d_rect = max(max(-px.x, px.x - w), max(-px.y, px.y - h));
	float inv_sqrt2 = 0.70710678;

	// Chanfro inferior esquerdo: (0, h-c) -> (c, h) => x + (h - y) >= c
	float d_bl = (c - (px.x + (h - px.y))) * inv_sqrt2;
	// Chanfro superior direito: (w-c, 0) -> (w, c) => (w - x) + y >= c
	float d_tr = (c - ((w - px.x) + px.y)) * inv_sqrt2;

	float dist = max(d_rect, max(d_bl, d_tr));

	if (dist > 0.0) {
		COLOR = vec4(0.0);
	} else if (dist > -border_width) {
		COLOR = border_color;
	} else {
		COLOR = fill_color;
	}
}
