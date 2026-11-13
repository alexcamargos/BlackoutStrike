## Moldura de Dossel Tatico (Canopy Framing Lines).
##
## Desenha os paineis azul-marinho translucidos com corte angular de 45 graus
## e bordas vetoriais ciano (#32D6FF) conforme VC-06 e 11_VISUAL_STYLE_GUIDE.md.
class_name HUDCanopyFraming
extends Control

@export var line_color: Color = Color(0.196, 0.839, 1.0, 0.85)
@export var panel_fill_color: Color = Color(0.04, 0.10, 0.17, 0.78)
@export var line_width: float = 1.5


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y

	# 1. Paineis Superiores Esquerdos (Armadura e Combustivel) com corte 45 graus
	var armor_poly: PackedVector2Array = PackedVector2Array([
		Vector2(16, 16),
		Vector2(382, 16),
		Vector2(348, 52),
		Vector2(16, 52)
	])
	_draw_chamfer_panel(armor_poly)

	var fuel_poly: PackedVector2Array = PackedVector2Array([
		Vector2(16, 58),
		Vector2(344, 58),
		Vector2(312, 92),
		Vector2(16, 92)
	])
	_draw_chamfer_panel(fuel_poly)

	# 2. Moldura Trapezoidal Superior Central (Fita de Azimute)
	var cx: float = w * 0.5
	var top_center_poly: PackedVector2Array = PackedVector2Array([
		Vector2(cx - 310.0, 0.0),
		Vector2(cx + 310.0, 0.0),
		Vector2(cx + 264.0, 46.0),
		Vector2(cx - 264.0, 46.0)
	])
	draw_colored_polygon(top_center_poly, panel_fill_color)
	var top_center_border: PackedVector2Array = PackedVector2Array([
		Vector2(cx - 310.0, 0.0),
		Vector2(cx - 264.0, 46.0),
		Vector2(cx + 264.0, 46.0),
		Vector2(cx + 310.0, 0.0)
	])
	draw_polyline(top_center_border, line_color, line_width)

	# 3. Painel Superior Direito (Passageiros) com corte 45 graus a esquerda
	var tr_poly: PackedVector2Array = PackedVector2Array([
		Vector2(w - 310.0, 16.0),
		Vector2(w - 16.0, 16.0),
		Vector2(w - 16.0, 64.0),
		Vector2(w - 270.0, 64.0),
		Vector2(w - 310.0, 36.0)
	])
	_draw_chamfer_panel(tr_poly)

	# 4. Painel Inferior Esquerdo (Radar) com corte 45 graus superior direito
	var bl_poly: PackedVector2Array = PackedVector2Array([
		Vector2(16.0, h - 222.0),
		Vector2(198.0, h - 222.0),
		Vector2(236.0, h - 184.0),
		Vector2(236.0, h - 14.0),
		Vector2(16.0, h - 14.0)
	])
	_draw_chamfer_panel(bl_poly)

	# Tiques de canto ao redor do radar
	_draw_corner_ticks(Vector2(26.0, h - 208.0), Vector2(214.0, h - 20.0), 12.0)

	# 5. Linha de conexao inferior central com degraus de 45 graus e tiques (estilo VC-06)
	var bc_left: PackedVector2Array = PackedVector2Array([
		Vector2(236.0, h - 18.0),
		Vector2(cx - 175.0, h - 18.0),
		Vector2(cx - 148.0, h - 42.0),
		Vector2(cx - 115.0, h - 42.0)
	])
	draw_polyline(bc_left, line_color * 0.75, line_width)

	var bc_right: PackedVector2Array = PackedVector2Array([
		Vector2(cx + 115.0, h - 42.0),
		Vector2(cx + 148.0, h - 42.0),
		Vector2(cx + 175.0, h - 18.0),
		Vector2(w - 348.0, h - 18.0)
	])
	draw_polyline(bc_right, line_color * 0.75, line_width)

	# Tiques verticais graduados ao longo da linha inferior central
	for i in range(4):
		var tx_l: float = cx - 225.0 + float(i) * 10.0
		var tx_r: float = cx + 195.0 + float(i) * 10.0
		draw_line(Vector2(tx_l, h - 25.0), Vector2(tx_l, h - 18.0), line_color * 0.85, 1.2)
		draw_line(Vector2(tx_r, h - 25.0), Vector2(tx_r, h - 18.0), line_color * 0.85, 1.2)


func _draw_chamfer_panel(points: PackedVector2Array) -> void:
	draw_colored_polygon(points, panel_fill_color)
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, line_color, line_width)


func _draw_corner_ticks(top_left: Vector2, bottom_right: Vector2, size_len: float) -> void:
	var tick_color: Color = Color(0.196, 0.839, 1.0, 0.85)
	draw_line(top_left, top_left + Vector2(size_len, 0), tick_color, 1.5)
	draw_line(top_left, top_left + Vector2(0, size_len), tick_color, 1.5)
	var top_right: Vector2 = Vector2(bottom_right.x, top_left.y)
	draw_line(top_right, top_right - Vector2(size_len, 0), tick_color, 1.5)
	draw_line(top_right, top_right + Vector2(0, size_len), tick_color, 1.5)
	var bot_left: Vector2 = Vector2(top_left.x, bottom_right.y)
	draw_line(bot_left, bot_left + Vector2(size_len, 0), tick_color, 1.5)
	draw_line(bot_left, bot_left - Vector2(0, size_len), tick_color, 1.5)
	draw_line(bottom_right, bottom_right - Vector2(size_len, 0), tick_color, 1.5)
	draw_line(bottom_right, bottom_right - Vector2(0, size_len), tick_color, 1.5)
