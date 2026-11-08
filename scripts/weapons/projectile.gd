## Entidade modular de projetil balistico e explosivo para armamentos.
##
## Controla deslocamento linear, teleguiamento opcional, tempo de vida util,
## aplicacao de dano direto ou em area e instanciacao de efeitos visuais de impacto.
class_name Projectile
extends Area3D

## Sinal emitido no instante em que o projetil colide com um obstaculo ou alvo valido.
signal impacted(hit_position: Vector3, collider: Node)

@export_group("Balistica")
## Dano base infligido ao atingir diretamente o alvo.
@export var damage: float = 14.0

## Velocidade linear de deslocamento em metros por segundo.
@export var speed: float = 120.0

## Tempo maximo de permanencia no espaco antes da autodestruicao (segundos).
@export var lifetime: float = 3.0

## Raio do dano colateral em metros. Se igual a 0, causa apenas dano pontual.
@export var explosion_radius: float = 0.0

## Quantidade de alvos que o projetil pode transpassar antes de detonar.
@export var pierce_remaining: int = 0

## Multiplicador aditivo de dano aplicado contra alvos do grupo 'structures'.
@export var structure_damage_bonus: float = 0.0

## Efeito visual ou de particulas instanciado no ponto de impacto.
@export var impact_effect_scene: PackedScene

@export_group("Teleguiamento")
## Define se a trajetoria do projetil se curva dinamicamente em direcao a um alvo.
@export var is_homing: bool = false

## Velocidade angular maxima de correcao de trajetoria em radianos por segundo.
@export var homing_turn_speed: float = 6.0

## Referencia ao alvo hostil rastreado pelo sistema de teleguiamento.
var homing_target: Node3D = null

## Referencia a entidade disparadora para prevenir colisao e fogo amigo imediato.
var source: Node3D = null

## Tempo decorrido de voo em segundos.
var elapsed_time: float = 0.0

## Flag que impede execucao multipla de impacto apos a destruicao.
var has_impacted: bool = false


## Inicializa conexoes de colisao e monitoramento de corpos e areas.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if is_homing:
		add_to_group("homing_missiles")


## Executa o avanco da simulacao fisica a cada quadro do motor.
##
## Args:
##     delta (float): Intervalo de tempo fisico em segundos.
##
## Returns:
##     void
func _physics_process(delta: float) -> void:
	simulate_step(delta)


## Atualiza o deslocamento espacial e o tempo de voo do projetil.
##
## Args:
##     delta (float): Passo de tempo em segundos.
##
## Returns:
##     void
func simulate_step(delta: float) -> void:
	if delta <= 0.0 or has_impacted:
		return
	
	elapsed_time += delta
	if elapsed_time >= lifetime:
		queue_free()
		return
	
	if is_homing and homing_target != null and is_instance_valid(homing_target):
		_process_homing(delta)
	else:
		var forward_vector: Vector3 = -global_transform.basis.z.normalized()
		global_position += forward_vector * speed * delta


## Ajusta a orientacao do vetor de trajetoria na direcao do alvo teleguiado.
##
## Args:
##     delta (float): Intervalo de tempo em segundos.
##
## Returns:
##     void
func _process_homing(delta: float) -> void:
	var target_vector: Vector3 = homing_target.global_position - global_position
	if target_vector.length_squared() > 0.01:
		var desired_forward: Vector3 = target_vector.normalized()
		var current_forward: Vector3 = -global_transform.basis.z.normalized()
		var new_forward: Vector3 = current_forward.slerp(desired_forward, homing_turn_speed * delta).normalized()
		
		# Mantem alinhamento do vetor Up para prevenir giros espurios
		var up_axis: Vector3 = Vector3.UP
		if absf(new_forward.dot(up_axis)) > 0.99:
			up_axis = Vector3.FORWARD
		var right_axis: Vector3 = up_axis.cross(new_forward).normalized()
		var corrected_up: Vector3 = new_forward.cross(right_axis).normalized()
		
		# No Godot 3D, Z aponta para tras (-new_forward)
		global_transform.basis = Basis(right_axis, corrected_up, -new_forward)
	
	var step_forward: Vector3 = -global_transform.basis.z.normalized()
	global_position += step_forward * speed * delta


## Quebra o travamento de teleguiamento do projetil (ex: acionado por contramedidas de Chaff).
##
## Desativa o modo teleguiado e remove o alvo atual, fazendo o projetil seguir em linha reta.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func break_homing_lock() -> void:
	is_homing = false
	homing_target = null


## Processa o impacto com um alvo fisico ou estrutura receptora de dano.
##
## Args:
##     target (Node): No atingido pelo projetil.
##
## Returns:
##     void
func handle_hit(target: Node) -> void:
	if target == null or target == source or has_impacted:
		return
	
	# Ignora no que faca parte da hierarquia do atirador
	if source != null and (source.is_ancestor_of(target) or target.is_ancestor_of(source)):
		return
	
	var final_damage: float = damage
	if target.is_in_group("structures"):
		final_damage *= (1.0 + structure_damage_bonus)
	
	if explosion_radius > 0.0:
		_apply_area_damage(global_position, final_damage)
	else:
		_apply_damage_to_node(target, final_damage)
	
	_spawn_impact_effect(global_position, target)
	impacted.emit(global_position, target)
	
	if pierce_remaining > 0:
		pierce_remaining -= 1
	else:
		has_impacted = true
		queue_free()


## Aplica dano em raio de explosao utilizando a matriz de colisao do espaco fisico.
##
## Args:
##     epicenter (Vector3): Ponto central da detonacao.
##     blast_damage (float): Intensidade do dano aplicado aos alvos na area.
##
## Returns:
##     void
func _apply_area_damage(epicenter: Vector3, blast_damage: float) -> void:
	var world_3d: World3D = get_world_3d()
	if world_3d == null:
		return
	
	var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	if space_state == null:
		return
	
	var shape_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = explosion_radius
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis.IDENTITY, epicenter)
	shape_query.collision_mask = collision_mask
	shape_query.collide_with_bodies = true
	shape_query.collide_with_areas = true
	
	var query_results: Array[Dictionary] = space_state.intersect_shape(shape_query, 32)
	var processed_targets: Array[Node] = []
	
	for entry in query_results:
		var collider: Object = entry.get("collider")
		if collider is Node and collider != source and not processed_targets.has(collider):
			processed_targets.append(collider as Node)
			_apply_damage_to_node(collider as Node, blast_damage)


## Transfere o dano nominal para o no receptor ou seu componente de vida.
##
## Args:
##     node (Node): Entidade que recebera a reducao de integridade.
##     amount (float): Valor positivo de dano a ser aplicado.
##
## Returns:
##     void
func _apply_damage_to_node(node: Node, amount: float) -> void:
	if node.has_method("take_damage"):
		node.take_damage(amount, source)
		return
	
	var health_comp: HealthComponent = _find_health_component(node)
	if health_comp != null:
		health_comp.take_damage(amount, source)
		return
	
	# Verifica se o no pai e uma entidade com componente de vida (ex: Area3D filha de um corpo)
	var parent_node: Node = node.get_parent()
	if parent_node != null:
		if parent_node.has_method("take_damage"):
			parent_node.take_damage(amount, source)
			return
		var parent_health: HealthComponent = _find_health_component(parent_node)
		if parent_health != null:
			parent_health.take_damage(amount, source)


## Localiza o HealthComponent em um no ou em seus filhos imediatos.
##
## Args:
##     node (Node): No a ser inspecionado.
##
## Returns:
##     HealthComponent: Instancia encontrada ou null.
func _find_health_component(node: Node) -> HealthComponent:
	if node is HealthComponent:
		return node as HealthComponent
	var direct_health: HealthComponent = node.get_node_or_null("HealthComponent") as HealthComponent
	if direct_health != null:
		return direct_health
	for child in node.get_children():
		if child is HealthComponent:
			return child as HealthComponent
	return null


## Instancia efeito visual ou particula no local do impacto conforme a superficie receptora.
##
## Args:
##     spawn_pos (Vector3): Coordenadas globais do efeito.
##     hit_target (Node): No receptor do impacto (opcional).
##
## Returns:
##     void
func _spawn_impact_effect(spawn_pos: Vector3, hit_target: Node = null) -> void:
	var current_tree: SceneTree = get_tree()
	if current_tree == null or current_tree.current_scene == null:
		return
	
	# Impactos na cota do oceano utilizam o efeito especializado de water splash
	if spawn_pos.y <= 0.3:
		var splash_scene: PackedScene = load("res://scenes/vfx/water_splash.tscn") as PackedScene
		if splash_scene != null:
			var splash_inst: Node3D = splash_scene.instantiate() as Node3D
			if splash_inst != null:
				current_tree.current_scene.add_child(splash_inst)
				splash_inst.global_position = spawn_pos
				return
	
	if impact_effect_scene == null:
		return
	var effect_instance: Node3D = impact_effect_scene.instantiate() as Node3D
	if effect_instance != null:
		current_tree.current_scene.add_child(effect_instance)
		effect_instance.global_position = spawn_pos
		if effect_instance.has_method("setup_for_target"):
			effect_instance.call("setup_for_target", hit_target, spawn_pos)


## Callback disparado quando um corpo fisico entra na area do projetil.
##
## Args:
##     body (Node3D): Corpo que interceptou o volume do projetil.
##
## Returns:
##     void
func _on_body_entered(body: Node3D) -> void:
	handle_hit(body)


## Callback disparado quando outra Area3D entra na area do projetil.
##
## Args:
##     area (Area3D): Area detectada pelo sensor do projetil.
##
## Returns:
##     void
func _on_area_entered(area: Area3D) -> void:
	handle_hit(area)
