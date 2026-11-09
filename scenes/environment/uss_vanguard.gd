class_name USSVanguard
extends Node3D

## Porta-avioes de comando e apoio operacional Forca-Tarefa Vanguard (USS Vanguard).
##
## Representa o ponto de insercao naval, reabastecimento estrategico e evacuacao
## de sobreviventes na Missao 01 (Atol de Midway). Oferece um conves de voo
## blindado com sinalizacoes de pista, torre de controle e defensas navais.

@export var radar_rotation_speed: float = 1.2
@export var nav_lights_pulse_speed: float = 2.0

@onready var radar_dish: Node3D = get_node_or_null("Superstructure/RadarMast/RadarDish") as Node3D
@onready var nav_light_deck: OmniLight3D = get_node_or_null("Lighting/DeckFloodLight") as OmniLight3D

var _light_pulse_time: float = 0.0


func _process(delta: float) -> void:
	"""Atualiza animacoes decorativas do porta-avioes (antena de radar e luzes).
	
	Args:
		delta: Tempo decorrido desde o ultimo frame em segundos.
	"""
	if radar_dish != null:
		radar_dish.rotate_y(radar_rotation_speed * delta)
	
	if nav_light_deck != null:
		_light_pulse_time += delta * nav_lights_pulse_speed
		nav_light_deck.light_energy = 1.0 + 0.3 * sin(_light_pulse_time)
