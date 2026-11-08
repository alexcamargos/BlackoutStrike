## Peca fragmentada de escombros instanciada no colapso de um abrigo.
##
## Possui fisica de queda livre/impacto contra o solo e desalocacao automatica.
class_name ShelterDebris
extends RigidBody3D

## Tempo de vida util dos escombros ate evaporarem do cenario (segundos).
@export var lifetime: float = 3.5

var _timer: float = 0.0


func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		set_physics_process(false)
		queue_free()
