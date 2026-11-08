## Efeito visual transiente de impacto de projetil com desalocacao automatica.
class_name ImpactEffect
extends Node3D

## Duracao de exibicao do efeito antes de liberar memoria (segundos).
@export var duration: float = 0.4

var timer: float = 0.0


## Controla o ciclo de vida e remocao automatica do efeito visual.
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
