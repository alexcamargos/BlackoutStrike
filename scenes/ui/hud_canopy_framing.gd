## Moldura de Dossel Tatico (Canopy Framing Lines).
##
## Desenha as linhas vetoriais ciano militares que conectam e enquadram
## os modulos de telemetria no viewport de 1080p conforme VC-06.
class_name HUDCanopyFraming
extends Control

@export var line_color: Color = Color(0.0, 0.88, 0.82, 0.75)
@export var line_width: float = 1.5


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	
	# 1. Moldura Superior Esquerda (Top-Left Bracket)
	# Envolve a baia de Armadura e Combustivel
	var tl_points: PackedVector2Array = PackedVector2Array([
		Vector2(16, 120),
		Vector2(16, 16),
		Vector2(380, 16),
		Vector2(405, 42),
		Vector2(405, 105),
		Vector2(385, 120),
		Vector2(16, 120)
	])
	draw_polyline(tl_points, line_color * 0.5, line_width)
	
	# 2. Moldura Superior Direita (Top-Right Bracket)
	# Envolve a baia de Passageiros
	var tr_points: PackedVector2Array = PackedVector2Array([
		Vector2(w - 16, 115),
		Vector2(w - 16, 16),
		Vector2(w - 325, 16),
		Vector2(w - 345, 38),
		Vector2(w - 345, 100),
		Vector2(w - 325, 115),
		Vector2(w - 16, 115)
	])
	draw_polyline(tr_points, line_color * 0.5, line_width)
	
	# 3. Moldura do Radar (Bottom-Left Bracket)
	var bl_points: PackedVector2Array = PackedVector2Array([
		Vector2(16, h - 225),
		Vector2(225, h - 225),
		Vector2(245, h - 205),
		Vector2(245, h - 16),
		Vector2(16, h - 16),
		Vector2(16, h - 225)
	])
	draw_polyline(bl_points, line_color * 0.5, line_width)
	
	# Tiques de canto ao redor do radar
	_draw_corner_ticks(Vector2(20, h - 220), Vector2(220, h - 20), 12.0)
	
	# 4. Moldura da Baia de Armas (Bottom-Right Bracket)
	var br_points: PackedVector2Array = PackedVector2Array([
		Vector2(w - 16, h - 210),
		Vector2(w - 335, h - 210),
		Vector2(w - 355, h - 190),
		Vector2(w - 355, h - 16),
		Vector2(w - 16, h - 16),
		Vector2(w - 16, h - 210)
	])
	draw_polyline(br_points, line_color * 0.5, line_width)
	
	# 5. Linha de conexao inferior central (Bottom-Center Guide Lines)
	var bc_left: PackedVector2Array = PackedVector2Array([
		Vector2(250, h - 35),
		Vector2(w * 0.5 - 150, h - 35),
		Vector2(w * 0.5 - 135, h - 18)
	])
	draw_polyline(bc_left, line_color * 0.45, line_width)
	
	var bc_right: PackedVector2Array = PackedVector2Array([
		Vector2(w * 0.5 + 135, h - 18),
		Vector2(w * 0.5 + 150, h - 35),
		Vector2(w - 360, h - 35)
	])
	draw_polyline(bc_right, line_color * 0.45, line_width)


func _draw_corner_ticks(top_left: Vector2, bottom_right: Vector2, size_len: float) -> void:
	var tick_color: Color = Color(0.0, 0.95, 0.9, 0.8)
	# Superior esquerdo
	draw_line(top_left, top_left + Vector2(size_len, 0), tick_color, 1.5)
	draw_line(top_left, top_left + Vector2(0, size_len), tick_color, 1.5)
	# Superior direito
	var top_right: Vector2 = Vector2(bottom_right.x, top_left.y)
	draw_line(top_right, top_right - Vector2(size_len, 0), tick_color, 1.5)
	draw_line(top_right, top_right + Vector2(0, size_len), tick_color, 1.5)
	# Inferior esquerdo
	var bot_left: Vector2 = Vector2(top_left.x, bottom_right.y)
	draw_line(bot_left, bot_left + Vector2(size_len, 0), tick_color, 1.5)
	draw_line(bot_left, bot_left - Vector2(0, size_len), tick_color, 1.5)
	# Inferior direito
	draw_line(bottom_right, bottom_right - Vector2(size_len, 0), tick_color, 1.5)
	draw_line(bottom_right, bottom_right - Vector2(0, size_len), tick_color, 1.5)
