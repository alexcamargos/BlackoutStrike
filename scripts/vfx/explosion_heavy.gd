## Prefab de explosao pesada em duas etapas com clarao pontual, bola de fogo e destrocos.
class_name ExplosionHeavy
extends Node3D

## Duracao total do ciclo de vida da explosao antes da desalocacao automatica (segundos).
@export var duration: float = 1.2

## Referencias aos subsistemas da explosao.
@onready var flash_light: OmniLight3D = get_node_or_null("FlashLight") as OmniLight3D
@onready var fireball_particles: GPUParticles3D = get_node_or_null("FireballParticles") as GPUParticles3D
@onready var debris_particles: GPUParticles3D = get_node_or_null("DebrisParticles") as GPUParticles3D

var timer: float = 0.0
var initial_light_energy: float = 8.0


## Inicializa a explosao pesada disparando as particulas e o clarao luminoso.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	if flash_light != null:
		initial_light_energy = flash_light.light_energy
	
	if fireball_particles != null:
		fireball_particles.emitting = true
		fireball_particles.restart()
	
	if debris_particles != null:
		debris_particles.emitting = true
		debris_particles.restart()


## Controla o decaimento exponencial do clarao e a remocao automatica do no.
##
## Args:
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func _process(delta: float) -> void:
	timer += delta
	
	# Etapa 1: Clarao pontual decaindo rapidamente nos primeiros 0.3 segundos
	if flash_light != null:
		var flash_decay: float = clampf(1.0 - (timer / 0.35), 0.0, 1.0)
		flash_light.light_energy = initial_light_energy * flash_decay * flash_decay
	
	# Etapa 2: Bola de fogo e fragmentos completam sua trajetoria balistica
	if timer >= duration:
		queue_free()
