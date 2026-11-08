## Componente responsavel pelo gerenciamento de vida e blindagem de entidades.
##
## Controla pontos de vida, invulnerabilidade, aplicacao de dano com rastreio de fonte,
## reparos e emissao de sinais de dano e destruicao.
class_name HealthComponent
extends Node

## Emitido sempre que o nivel atual ou maximo de saude for alterado.
signal health_changed(current: float, max_health: float)

## Emitido quando a saude atinge zero e a entidade e destruida.
signal entity_destroyed()

## Limite maximo de pontos de vida da entidade.
@export var max_health: float = 1000.0

## Pontos de vida atuais da entidade.
@export var current_health: float = 1000.0

## Indica se a entidade ignora temporariamente ou permanentemente qualquer dano.
@export var is_invulnerable: bool = false


## Aplica dano a entidade, reduzindo pontos de vida e emitindo sinais.
##
## Args:
##     amount (float): Quantidade de dano a aplicar (deve ser positiva).
##     source (Node3D): Instancia causadora do dano (opcional).
##
## Returns:
##     void
func take_damage(amount: float, source: Node3D = null) -> void:
	if amount <= 0.0 or is_invulnerable or is_destroyed():
		return
	
	var was_alive: bool = not is_destroyed()
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if was_alive and is_destroyed():
		entity_destroyed.emit()


## Restaura pontos de vida da entidade, respeitando o limite maximo de vida.
##
## Args:
##     amount (float): Quantidade de vida a restaurar (deve ser positiva).
##
## Returns:
##     void
func repair(amount: float) -> void:
	if amount <= 0.0 or is_destroyed():
		return
	
	var previous_health: float = current_health
	current_health = minf(max_health, current_health + amount)
	
	if not is_equal_approx(previous_health, current_health):
		health_changed.emit(current_health, max_health)


## Verifica se a entidade esta totalmente destruida (vida zerada).
##
## Args:
##     Nenhum.
##
## Returns:
##     bool: True se a vida for menor ou igual a zero; False caso contrario.
func is_destroyed() -> bool:
	return current_health <= 0.0
