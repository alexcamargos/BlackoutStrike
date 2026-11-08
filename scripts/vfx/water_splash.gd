## Efeito visual transiente de borrifo vertical de agua marinha com desalocacao automatica.
class_name WaterSplash
extends Node3D

## Duracao total de exibicao do borrifo antes da liberacao de memoria (segundos).
@export var duration: float = 0.65

## Referencia ao emissor de particulas GPU de gotas.
@onready var splash_particles: GPUParticles3D = get_node_or_null("SplashParticles") as GPUParticles3D

var timer: float = 0.0


## Inicializa o borrifo ativando as particulas ascendentes.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	if splash_particles != null:
		splash_particles.emitting = true
		splash_particles.restart()


## Controla o ciclo de vida e a desalocacao automatica do efeito de borrifo.
##
## Args:
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func _process(delta: float) -> void:
	timer += delta
	if timer >= duration:
		queue_free()
