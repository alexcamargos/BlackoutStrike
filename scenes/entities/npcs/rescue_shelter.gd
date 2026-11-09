## Estrutura blindada de abrigo destrutivel contendo especialistas refens.
##
## Protege os sobreviventes com 300.0 HP de integridade estrutural. Ao sofrer colapso,
## notifica o EventBus e libera 4 civis em dispersao radial ao redor da fundacao.
class_name RescueShelter
extends StaticBody3D

## Recurso de configuracao dos atributos do abrigo.
@export var shelter_data: ShelterData

## Cena instanciada para cada sobrevivente liberado no colapso.
@export var civilian_scene: PackedScene

## Cena dos escombros instanciados na destruicao estrutural.
@export var debris_scene: PackedScene = preload("res://scenes/entities/npcs/shelter_debris.tscn")

## Referencia ao componente de integridade estrutural.
@onready var health_component: HealthComponent = $HealthComponent

## Flag para prevenir liberacao duplicada durante o frame de exclusao.
var is_collapsed: bool = false


## Configura o abrigo adicionando ao grupo de estruturas e sincronizando saude.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	add_to_group("structures")
	
	if shelter_data == null:
		shelter_data = preload("res://scripts/data/rescue_shelter.tres")
	
	if civilian_scene == null:
		civilian_scene = preload("res://scenes/entities/npcs/civilian.tscn")
	
	if health_component != null and shelter_data != null:
		health_component.max_health = shelter_data.max_health
		health_component.current_health = shelter_data.max_health
		health_component.entity_destroyed.connect(_on_entity_destroyed)


## Aplica dano a estrutura delegando a operacao ao HealthComponent.
##
## Args:
##     amount (float): Intensidade do dano a aplicar.
##     source (Node3D): Instancia originadora do ataque (opcional).
##
## Returns:
##     void
func take_damage(amount: float, source: Node3D = null) -> void:
	if is_collapsed:
		return
	if health_component != null:
		health_component.take_damage(amount, source)


## Processa a destruicao do edificio, emissao de sinais e geracao dos sobreviventes.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_entity_destroyed() -> void:
	if is_collapsed:
		return
	is_collapsed = true
	
	var survivor_count: int = 4
	var scatter_radius: float = 2.5
	
	if shelter_data != null:
		survivor_count = shelter_data.survivor_count
		scatter_radius = shelter_data.spawn_scatter_radius
	
	if EventBus != null:
		EventBus.shelter_destroyed.emit(global_position, survivor_count)
	
	_spawn_destruction_explosion(global_position)
	_spawn_survivors(survivor_count, scatter_radius)
	_spawn_debris()
	queue_free()


## Instancia efeito de explosao pesada no colapso da estrutura de abrigo.
##
## Args:
##     pos (Vector3): Coordenadas da detonacao.
##
## Returns:
##     void
func _spawn_destruction_explosion(pos: Vector3) -> void:
	var tree: SceneTree = get_tree()
	var spawn_parent: Node = null
	if tree != null and tree.current_scene != null:
		spawn_parent = tree.current_scene
	elif get_parent() != null and get_parent().is_inside_tree():
		spawn_parent = get_parent()
	
	if spawn_parent == null:
		return
	
	var explosion_scene: PackedScene = preload("res://scenes/vfx/explosion_heavy.tscn")
	var explosion_inst: Node3D = explosion_scene.instantiate() as Node3D
	if explosion_inst != null:
		spawn_parent.add_child(explosion_inst)
		explosion_inst.global_position = pos


## Gera pecas fragmentadas de escombros de concreto ao redor da fundacao do abrigo.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _spawn_debris() -> void:
	if debris_scene == null:
		return
	var target_parent: Node = get_parent()
	if target_parent == null:
		return
	
	for i in range(6):
		var debris_inst: Node = debris_scene.instantiate()
		var rb: RigidBody3D = debris_inst as RigidBody3D
		if rb == null:
			debris_inst.queue_free()
			continue
		
		var angle: float = float(i) * (TAU / 6.0)
		var offset: Vector3 = Vector3(cos(angle), 0.8, sin(angle)) * 1.5
		var impulse: Vector3 = Vector3(cos(angle) * randf_range(2.0, 4.5), randf_range(3.0, 5.5), sin(angle) * randf_range(2.0, 4.5))
		
		target_parent.add_child(rb)
		rb.global_position = global_position + offset
		rb.apply_central_impulse(impulse)



## Localiza o no container canônico para os sobreviventes na arvore da cena.
##
## Args:
##     Nenhum.
##
## Returns:
##     Node: No pai adequado para alocacao dos civis liberados.
func _resolve_civilian_container() -> Node:
	var tree: SceneTree = get_tree()
	if tree != null:
		var container_nodes: Array[Node] = tree.get_nodes_in_group("civilian_container")
		if not container_nodes.is_empty():
			return container_nodes[0]
		
		if tree.current_scene != null:
			var active_entities: Node = tree.current_scene.get_node_or_null("ActiveEntities/Civilians")
			if active_entities != null:
				return active_entities
	
	var parent_container: Node = get_parent()
	return parent_container if parent_container != null else self


## Gera as instancias dos civis distribuindo-as radialmente ao redor do abrigo.
##
## Args:
##     count (int): Numero de sobreviventes a instanciar.
##     radius (float): Distancia radial da fundacao em metros.
##
## Returns:
##     void
func _spawn_survivors(count: int, radius: float) -> void:
	if civilian_scene == null or count <= 0:
		return
	
	var target_container: Node = _resolve_civilian_container()
	
	for i in range(count):
		var survivor_node: Node = civilian_scene.instantiate()
		var civilian: Node3D = survivor_node as Node3D
		if civilian == null:
			continue
		
		var angle: float = float(i) * (TAU / float(count))
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * radius
		
		if target_container != self:
			target_container.add_child(civilian)
			civilian.global_position = global_position + offset
		else:
			# Fallback se nao possuir pai anexado na arvore
			add_child(civilian)
			civilian.position = offset
