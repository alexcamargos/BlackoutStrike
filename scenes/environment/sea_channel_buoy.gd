class_name SeaChannelBuoy
extends Node3D

## Boia de balizamento maritimo e sinalizacao de canal de navegacao.
##
## Emite sinal luminoso intermitente (verde ou vermelho) para orientar
## aeronaves e embarcacoes no corredor seguro entre a forca-tarefa e a costa.

@export var is_port_marker: bool = false
@export var blink_speed: float = 3.0

@onready var light: OmniLight3D = get_node_or_null("StrobeLight") as OmniLight3D
@onready var bulb_mesh: MeshInstance3D = get_node_or_null("BuoyMesh/StrobeBulb") as MeshInstance3D

var _timer: float = 0.0


func _ready() -> void:
	if light != null:
		var beacon_color: Color = Color(0.1, 0.95, 0.3, 1.0) if not is_port_marker else Color(0.95, 0.15, 0.15, 1.0)
		light.light_color = beacon_color


func _process(delta: float) -> void:
	"""Atualiza o piscar do sinalizador luminoso da boia naval.
	
	Args:
		delta: Intervalo de tempo do quadro em segundos.
	"""
	_timer += delta * blink_speed
	var pulse: float = maxf(0.0, sin(_timer))
	if light != null:
		light.light_energy = 0.2 + (pulse * 2.0)
