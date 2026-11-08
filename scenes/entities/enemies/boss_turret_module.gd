## Sub-entidade modular de torreta do chefe Apex Bastion.
##
## Gerencia vida independente, orientação e disparo dos sistemas de armas.
class_name BossTurretModule
extends StaticBody3D

signal turret_destroyed()

@export var max_health: float = 800.0
@export var is_bow_turret: bool = true

@onready var health: HealthComponent = $HealthComponent

var is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("structures")
	
	if health != null:
		health.max_health = max_health
		health.current_health = max_health
		health.entity_destroyed.connect(_on_entity_destroyed)


func take_damage(amount: float, source: Node3D = null) -> void:
	if not is_dead and health != null:
		health.take_damage(amount, source)


func is_destroyed() -> bool:
	return is_dead or (health != null and health.is_destroyed())


func _on_entity_destroyed() -> void:
	if is_dead:
		return
	is_dead = true
	turret_destroyed.emit()
