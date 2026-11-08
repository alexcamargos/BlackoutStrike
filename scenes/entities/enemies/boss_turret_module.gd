## Sub-entidade modular de torreta do chefe Apex Bastion.
##
## Gerencia vida independente, orientação e disparo dos sistemas de armas.
class_name BossTurretModule
extends StaticBody3D

signal turret_destroyed()

@export var max_health: float = 800.0
@export var is_bow_turret: bool = true

## Material PBR aplicado às malhas da torreta após colapso estrutural (avariada/enfumaçada).
@export var damaged_material: StandardMaterial3D = null

@onready var health: HealthComponent = $HealthComponent

var is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("structures")
	
	if damaged_material == null:
		damaged_material = StandardMaterial3D.new()
		damaged_material.albedo_color = Color(0.08, 0.08, 0.08, 1.0) # Preto carbonizado
		damaged_material.metallic = 0.2
		damaged_material.roughness = 0.9
		damaged_material.emission_enabled = true
		damaged_material.emission = Color(0.35, 0.12, 0.04, 1.0) # Brasas residuais
		damaged_material.emission_energy_multiplier = 0.8
	
	if health != null:
		health.max_health = max_health
		health.current_health = max_health
		health.entity_destroyed.connect(_on_entity_destroyed)


func take_damage(amount: float, source: Node3D = null) -> void:
	if not is_dead and health != null:
		health.take_damage(amount, source)


func is_destroyed() -> bool:
	return is_dead or (health != null and health.is_destroyed())


## Orienta suavemente a torreta em torno do eixo Y em direção ao alvo tático.
##
## Args:
##     target_pos (Vector3): Posição global do alvo visado.
##     delta (float): Intervalo de tempo físico em segundos.
##
## Returns:
##     void
func orient_towards(target_pos: Vector3, delta: float) -> void:
	if is_dead:
		return
	var dir: Vector3 = target_pos - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		var target_basis: Basis = Basis.looking_at(dir.normalized(), Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, clampf(4.0 * delta, 0.0, 1.0))


func _on_entity_destroyed() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	_apply_damaged_material()
	turret_destroyed.emit()


## Aplica o material carbonizado/avariado a todas as malhas pertencentes ao módulo da torreta.
func _apply_damaged_material() -> void:
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			curr.set_surface_override_material(0, damaged_material)
		for child in curr.get_children():
			stack.append(child)

