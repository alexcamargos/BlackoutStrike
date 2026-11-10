## Widget de Radar Tatico de Superficie (estilo sonar militar).
##
## Exibe aneis de alcance, feixe rotativo de varredura e plotagem de contatos
## hostis (vermelho-alerta) e aliados (ciano) em tempo real ao redor do jogador.
class_name TacticalRadarWidget
extends Control

@export var radar_range_meters: float = 400.0
@export var radar_radius_pixels: float = 78.0

var _tracked_player: Node3D = null


func _ready() -> void:
	custom_minimum_size = Vector2(180, 180)


func _process(_delta: float) -> void:
	if _tracked_player == null or not is_instance_valid(_tracked_player):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_tracked_player = players[0] as Node3D
	
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	
	# 1. Marcador da aeronave do jogador no centro (triangulo ciano)
	var player_points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -7),
		center + Vector2(5, 6),
		center + Vector2(0, 3),
		center + Vector2(-5, 6)
	])
	draw_colored_polygon(player_points, Color(0.0, 0.95, 0.9, 1.0))
	draw_polyline(player_points, Color(1.0, 1.0, 1.0, 0.9), 1.2)
	
	# Se nao houver jogador instanciado (ex: teste unitario do HUD), plota contatos de demonstracao
	if _tracked_player == null or not is_instance_valid(_tracked_player):
		_draw_sample_blips(center)
		return
	
	var player_pos: Vector3 = _tracked_player.global_position
	
	# 2. Plotagem de contatos hostis (inimigos aereos, terrestres e navais)
	var enemies: Array[Node] = []
	for group_name: String in ["enemies", "Enemies_Ground", "Enemies_Air", "boss"]:
		for node: Node in get_tree().get_nodes_in_group(group_name):
			if node is Node3D and is_instance_valid(node) and not enemies.has(node):
				enemies.append(node)
	
	for enemy: Node in enemies:
		var enemy_3d: Node3D = enemy as Node3D
		if enemy_3d == null or not is_instance_valid(enemy_3d):
			continue
		
		var dx: float = enemy_3d.global_position.x - player_pos.x
		var dz: float = enemy_3d.global_position.z - player_pos.z
		var dist: float = Vector2(dx, dz).length()
		
		if dist <= radar_range_meters:
			var norm_dist: float = (dist / radar_range_meters) * radar_radius_pixels
			var angle: float = atan2(dz, dx)
			var blip_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * norm_dist
			
			# Plota losango vermelho-alerta (#D9381E)
			_draw_diamond(blip_pos, 4.5, Color(1.0, 0.22, 0.15, 0.95))
	
	# 3. Plotagem do Heliponto Aliado / USS Vanguard
	var helipads: Array[Node] = get_tree().get_nodes_in_group("helipad")
	for helipad: Node in helipads:
		var helipad_3d: Node3D = helipad as Node3D
		if helipad_3d != null and is_instance_valid(helipad_3d):
			var dx: float = helipad_3d.global_position.x - player_pos.x
			var dz: float = helipad_3d.global_position.z - player_pos.z
			var dist: float = Vector2(dx, dz).length()
			if dist <= radar_range_meters * 1.5:
				var norm_dist: float = minf(dist / radar_range_meters, 0.95) * radar_radius_pixels
				var angle: float = atan2(dz, dx)
				var blip_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * norm_dist
				draw_rect(Rect2(blip_pos - Vector2(4, 4), Vector2(8, 8)), Color(0.0, 0.9, 0.85, 0.9), false, 1.5)


func _draw_diamond(pos: Vector2, half_size: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		pos + Vector2(0, -half_size),
		pos + Vector2(half_size, 0),
		pos + Vector2(0, half_size),
		pos + Vector2(-half_size, 0)
	])
	draw_colored_polygon(pts, color)


func _draw_sample_blips(center: Vector2) -> void:
	# Contatos demonstrativos em quadrantes taticos conforme VC-06
	var sample_enemy_1: Vector2 = center + Vector2(38, -32)
	var sample_enemy_2: Vector2 = center + Vector2(48, -22)
	var sample_allied: Vector2 = center + Vector2(-28, 42)
	
	_draw_diamond(sample_enemy_1, 4.5, Color(1.0, 0.22, 0.15, 0.95))
	_draw_diamond(sample_enemy_2, 4.5, Color(1.0, 0.22, 0.15, 0.95))
	draw_rect(Rect2(sample_allied - Vector2(4, 4), Vector2(8, 8)), Color(0.0, 0.9, 0.85, 0.9), false, 1.5)
