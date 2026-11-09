## Controlador Modular de Inteligência Artificial para Unidades Hostis.
##
## Gerencia máquinas de estados conforme EnemyStatsData.BehaviorType:
## - STATIC_TURRET: Sentinela fixa girando e disparando contra alvos no alcance.
## - GROUND_PATROL: Patrulha terrestre por waypoints e perseguição.
## - NAVAL_PATROL: Patrulha em circuitos náuticos.
## - AIR_INTERCEPTOR: Interceptação aérea agressiva com ajuste de cota.
## Suporta supressão de resgate, disparo balístico/homing e drop de suprimentos ao morrer.
class_name EnemyAIController
extends Node

const EXPLOSION_HEAVY_SCENE: PackedScene = preload("res://scenes/vfx/explosion_heavy.tscn")
const SFX_ENEMY_SHOT: AudioStream = preload("res://assets/audio/sfx_vulcan_shot.wav")

## Player acustico 3D para feedback espacial dos disparos hostis.
var enemy_audio: AudioStreamPlayer3D = null

## Sinal emitido quando a entidade dispara um projétil.
signal weapon_fired(projectile: Projectile)

## Sinal emitido ao morrer ou ser destruído.
signal enemy_killed(enemy_node: Node3D)

## Recurso com as estatísticas e tipo de comportamento da unidade.
@export var stats: EnemyStatsData:
	get:
		return stats_data
	set(val):
		stats_data = val
@export var stats_data: EnemyStatsData

## Cena do projétil a ser instanciado nos disparos.
@export var projectile_scene: PackedScene

## Cena do drop de suprimentos (SupplyPickup).
@export var supply_pickup_scene: PackedScene

## Waypoints opcionais no espaço global para patrulha de solo ou naval.
@export var patrol_waypoints: Array[Vector3] = []

## Referência opcional ao corpo 3D hostil pai (CharacterBody3D, StaticBody3D, etc.).
var parent_body: Node3D = null

## Referência ao HealthComponent da entidade.
var health_component: HealthComponent = null

## Temporizador para cadência de disparos.
var fire_timer: float = 0.0

## Índice do waypoint atual de patrulha.
var current_waypoint_index: int = 0

## Alvo prioritário (PlayerHelicopter).
var target_player: Node3D = null

## Flag indicando se a unidade já iniciou sequência de morte.
var is_dead: bool = false

## Nó móvel de torreta para apontamento desacoplado em direção ao alvo.
@export var turret_node: Node3D = null

## Marcador de origem balística espacial dos projéteis disparados.
@export var muzzle_marker: Marker3D = null


## Inicializa o controlador, detecta o nó pai e componentes associados.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	parent_body = get_parent() as Node3D
	if parent_body != null:
		health_component = parent_body.get_node_or_null("HealthComponent") as HealthComponent
		if health_component != null:
			if stats_data != null:
				health_component.max_health = stats_data.max_health
				health_component.current_health = stats_data.max_health
			health_component.entity_destroyed.connect(_on_entity_destroyed)
		
		# Detecta automaticamente nós de torreta e muzzle se não exportados
		if turret_node == null:
			turret_node = parent_body.get_node_or_null("Turret") as Node3D
			if turret_node == null:
				turret_node = parent_body.get_node_or_null("ModelContainer/Turret") as Node3D
		if muzzle_marker == null:
			if turret_node != null:
				muzzle_marker = turret_node.get_node_or_null("Muzzle") as Marker3D
			if muzzle_marker == null:
				muzzle_marker = parent_body.get_node_or_null("Muzzle") as Marker3D
		
		# Configura grupos padrão
		parent_body.add_to_group("enemies")
		if stats_data != null:
			if stats_data.behavior == EnemyStatsData.BehaviorType.AIR_INTERCEPTOR:
				parent_body.add_to_group("air_enemies")
			else:
				parent_body.add_to_group("ground_enemies")

	
	if supply_pickup_scene == null:
		supply_pickup_scene = load("res://scenes/roguelite/supply_pickup.tscn") as PackedScene
	
	if projectile_scene == null:
		_load_default_projectile()
	
	if patrol_waypoints.is_empty() and stats_data != null and parent_body != null:
		_setup_default_patrol_circuit()
	
	enemy_audio = get_node_or_null("EnemyAudioPlayer") as AudioStreamPlayer3D
	if enemy_audio == null:
		enemy_audio = AudioStreamPlayer3D.new()
		enemy_audio.name = "EnemyAudioPlayer"
		enemy_audio.bus = &"SFX_Combat"
		enemy_audio.max_distance = 45.0
		add_child(enemy_audio)


## Executa a lógica de IA a cada passo de física.
##
## Args:
##     delta (float): Intervalo de tempo em segundos.
##
## Returns:
##     void
func _physics_process(delta: float) -> void:
	if is_dead or parent_body == null or stats_data == null:
		return
	
	_update_target_player()
	_update_combat_loop(delta)
	_update_movement(delta)
	_update_procedural_animations(delta)


## Executa micro-animações procedurais conforme o arquétipo hostil (bobbing aéreo, balanço náutico, oscilação de radar).
##
## Args:
##     delta (float): Intervalo de tempo em segundos.
##
## Returns:
##     void
func _update_procedural_animations(delta: float) -> void:
	if parent_body == null or not is_instance_valid(parent_body) or not parent_body.is_inside_tree():
		return
	
	var model: Node3D = parent_body.get_node_or_null("ModelContainer") as Node3D
	if model == null:
		return
	
	var t: float = float(Time.get_ticks_msec()) * 0.004
	match stats_data.behavior:
		EnemyStatsData.BehaviorType.AIR_INTERCEPTOR:
			model.position.y = sin(t * 1.5) * 0.12
			model.rotation.z = sin(t) * 0.05
		EnemyStatsData.BehaviorType.NAVAL_PATROL:
			model.rotation.x = sin(t * 1.2) * 0.04
			model.rotation.z = cos(t * 0.9) * 0.04
		EnemyStatsData.BehaviorType.STATIC_TURRET:
			if turret_node != null and is_instance_valid(turret_node):
				var radar: Node3D = turret_node.get_node_or_null("RadarDome") as Node3D
				if radar != null:
					radar.rotate_y(2.5 * delta)


## Atualiza a referência do jogador ativo na árvore de cena.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _update_target_player() -> void:
	if target_player != null and is_instance_valid(target_player):
		return
	
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var players: Array[Node] = tree.get_nodes_in_group("player")
	if not players.is_empty():
		target_player = players[0] as Node3D


## Atualiza temporizador de disparo e engaja o alvo quando dentro do alcance.
##
## Args:
##     delta (float): Intervalo de tempo em segundos.
##
## Returns:
##     void
func _update_combat_loop(delta: float) -> void:
	fire_timer += delta
	if target_player == null or not is_instance_valid(target_player):
		return
	
	var dist: float = parent_body.global_position.distance_to(target_player.global_position)
	if dist <= stats_data.detection_range:
		_orient_towards(target_player.global_position, delta)
		if fire_timer >= stats_data.fire_interval:
			fire_timer = 0.0
			fire_weapon_at(target_player)


## Orienta suavemente a entidade ou sua torreta em direção ao alvo.
##
## Args:
##     target_pos (Vector3): Posição no espaço global para encarar.
##     delta (float): Passo de tempo.
##
## Returns:
##     void
func _orient_towards(target_pos: Vector3, delta: float) -> void:
	if parent_body == null or not is_instance_valid(parent_body):
		return
	
	var my_pos: Vector3 = parent_body.global_position
	var look_dir: Vector3 = (target_pos - my_pos)
	var is_air: bool = stats_data != null and stats_data.behavior == EnemyStatsData.BehaviorType.AIR_INTERCEPTOR
	var is_static: bool = stats_data != null and stats_data.behavior == EnemyStatsData.BehaviorType.STATIC_TURRET
	
	if not is_air:
		look_dir.y = 0.0
	
	if look_dir.length_squared() > 0.01:
		var target_basis: Basis = Basis.looking_at(look_dir.normalized(), Vector3.UP)
		
		# 1. Corpo pai rotaciona suavemente primeiro (exceto STATIC_TURRET, cuja base permanece estática)
		if not is_static:
			parent_body.global_transform.basis = parent_body.global_transform.basis.slerp(target_basis, clampf(6.0 * delta, 0.0, 1.0))
		
		# 2. Apontamento angular da torreta desacoplada em direção ao alvo calculado após a rotação da base
		if turret_node != null and is_instance_valid(turret_node):
			var turret_pos: Vector3 = turret_node.global_position
			var turret_dir: Vector3 = (target_pos - turret_pos)
			if not is_air and not is_static:
				turret_dir.y = 0.0
			if turret_dir.length_squared() > 0.01:
				var t_basis: Basis = Basis.looking_at(turret_dir.normalized(), Vector3.UP)
				turret_node.global_transform.basis = turret_node.global_transform.basis.slerp(t_basis, clampf(8.0 * delta, 0.0, 1.0))


## Dispara um projétil contra o alvo especificado.
##
## Args:
##     target (Node3D): Alvo inimigo visado.
##
## Returns:
##     Projectile: Instância do projétil gerado ou null.
func fire_weapon_at(target: Node3D) -> Projectile:
	if projectile_scene == null or parent_body == null:
		return null
	
	var proj_instance: Node = projectile_scene.instantiate()
	var projectile: Projectile = proj_instance as Projectile
	if projectile == null:
		proj_instance.queue_free()
		return null
	
	# Configura parâmetros balísticos oriundos do stats_data
	if stats_data != null:
		projectile.damage = stats_data.projectile_damage
		projectile.speed = stats_data.projectile_speed
		projectile.explosion_radius = stats_data.projectile_explosion_radius
		projectile.is_homing = stats_data.is_homing_projectile
	
	projectile.source = parent_body
	if projectile.is_homing and target != null:
		projectile.homing_target = target
	
	# Posição e orientação de saída
	var muzzle_pos: Vector3 = parent_body.global_position if parent_body.is_inside_tree() else parent_body.position
	if muzzle_marker != null and is_instance_valid(muzzle_marker) and muzzle_marker.is_inside_tree():
		muzzle_pos = muzzle_marker.global_position
	
	var target_pos: Vector3 = target.global_position if (target != null and target.is_inside_tree()) else (target.position if target != null else Vector3.ZERO)
	
	var parent_tree: Node = parent_body.get_parent()
	if parent_tree != null and parent_tree.is_inside_tree():
		parent_tree.add_child(projectile)
	elif parent_body.is_inside_tree():
		parent_body.add_sibling(projectile)
	else:
		parent_body.add_child(projectile)
	
	var shot_dir: Vector3 = -parent_body.global_transform.basis.z.normalized() if parent_body.is_inside_tree() else Vector3.FORWARD
	if turret_node != null and is_instance_valid(turret_node) and turret_node.is_inside_tree():
		shot_dir = -turret_node.global_transform.basis.z.normalized()
	elif target != null:
		var dir_to_target: Vector3 = (target_pos - muzzle_pos).normalized()
		if dir_to_target.length_squared() > 0.01:
			shot_dir = dir_to_target
	
	projectile.global_position = muzzle_pos + shot_dir * 0.8
	if shot_dir.length_squared() > 0.01:
		var target_look: Vector3 = projectile.global_position + shot_dir
		if projectile.is_inside_tree():
			projectile.look_at(target_look, Vector3.UP)
	
	if enemy_audio != null:
		enemy_audio.stream = SFX_ENEMY_SHOT
		enemy_audio.pitch_scale = randf_range(1.1, 1.25)
		if enemy_audio.stream != null:
			enemy_audio.play()
	
	weapon_fired.emit(projectile)
	return projectile


## Gerencia o deslocamento conforme o padrão comportamental.
##
## Args:
##     delta (float): Intervalo de tempo.
##
## Returns:
##     void
func _update_movement(delta: float) -> void:
	if stats_data.move_speed <= 0.0:
		return
	
	match stats_data.behavior:
		EnemyStatsData.BehaviorType.STATIC_TURRET:
			return
		
		EnemyStatsData.BehaviorType.GROUND_PATROL, EnemyStatsData.BehaviorType.NAVAL_PATROL:
			_move_along_patrol(delta)
		
		EnemyStatsData.BehaviorType.AIR_INTERCEPTOR:
			_move_air_interceptor(delta)


## Patrulha waypoints predefinidos ou perambula em torno do ponto de origem.
##
## Args:
##     delta (float): Intervalo de tempo.
##
## Returns:
##     void
func _move_along_patrol(delta: float) -> void:
	if patrol_waypoints.is_empty():
		return
	
	var dest: Vector3 = patrol_waypoints[current_waypoint_index]
	var current_pos: Vector3 = parent_body.global_position
	var diff: Vector3 = dest - current_pos
	diff.y = 0.0
	
	if diff.length() < 1.5:
		current_waypoint_index = (current_waypoint_index + 1) % patrol_waypoints.size()
		return
	
	var dir: Vector3 = diff.normalized()
	var step: Vector3 = dir * stats_data.move_speed * delta
	
	if parent_body is CharacterBody3D:
		var cb: CharacterBody3D = parent_body as CharacterBody3D
		cb.velocity = dir * stats_data.move_speed
		cb.move_and_slide()
	else:
		parent_body.global_position += step


## Movimenta drone aéreo convergindo sobre o jogador e mantendo cota de voo.
##
## Args:
##     delta (float): Intervalo de tempo.
##
## Returns:
##     void
func _move_air_interceptor(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	
	var dest: Vector3 = target_player.global_position
	var current_pos: Vector3 = parent_body.global_position
	var diff: Vector3 = dest - current_pos
	
	# Mantém distância de combate sem sobrepor colisão física
	var dist: float = diff.length()
	if dist > 6.0:
		var dir: Vector3 = diff.normalized()
		var step: Vector3 = dir * stats_data.move_speed * delta
		if parent_body is CharacterBody3D:
			var cb: CharacterBody3D = parent_body as CharacterBody3D
			cb.velocity = dir * stats_data.move_speed
			cb.move_and_slide()
		else:
			parent_body.global_position += step


## Computa a velocidade direcional vetorial de deslocamento em direção a um destino.
##
## Args:
##     current_pos (Vector3): Posição atual de origem da entidade.
##     target_pos (Vector3): Posição de destino almejada.
##     delta (float): Intervalo de tempo do frame de física.
##
## Returns:
##     Vector3: Vetor velocidade linear a ser aplicado.
func compute_movement_velocity(current_pos: Vector3, target_pos: Vector3, delta: float) -> Vector3:
	var speed: float = stats_data.move_speed if stats_data != null else 0.0
	if speed <= 0.0:
		return Vector3.ZERO
	
	var diff: Vector3 = target_pos - current_pos
	if stats_data != null and stats_data.behavior != EnemyStatsData.BehaviorType.AIR_INTERCEPTOR:
		diff.y = 0.0
	
	if diff.length_squared() < 0.01:
		return Vector3.ZERO
	
	return diff.normalized() * speed


## Avalia se o alvo está dentro do alcance de detecção e combate da unidade.
##
## Args:
##     current_pos (Vector3): Posição atual da entidade hostil.
##     target_pos (Vector3): Posição da entidade a ser engajada.
##
## Returns:
##     bool: true se a distância for menor ou igual a stats_data.detection_range.
func can_engage_target(current_pos: Vector3, target_pos: Vector3) -> bool:
	if stats_data == null:
		return false
	return current_pos.distance_to(target_pos) <= stats_data.detection_range


## Avalia se a entidade está suprimindo a operação de resgate na posição de civis.
##
## Args:
##     enemy_pos (Vector3): Posição global do inimigo.
##     civilian_pos (Vector3): Posição global dos sobreviventes.
##
## Returns:
##     bool: true se a unidade estiver configurada para suprimir e dentro do raio.
func is_suppressing_position(enemy_pos: Vector3, civilian_pos: Vector3) -> bool:
	if is_dead or stats_data == null or not stats_data.suppresses_rescue_ring:
		return false
	var dist: float = enemy_pos.distance_to(civilian_pos)
	return dist <= stats_data.suppression_radius


## Processa destruição, concede chance de drop de suprimentos e libera nó.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_entity_destroyed() -> void:
	if is_dead:
		return
	is_dead = true
	
	if parent_body != null:
		var death_pos: Vector3 = parent_body.global_position if parent_body.is_inside_tree() else parent_body.position
		enemy_killed.emit(parent_body)
		_try_spawn_supply_drop(death_pos)
		_spawn_heavy_explosion(death_pos)
		parent_body.queue_free()


## Sorteia e instancia drop de munição ou combustível caso contemplado.
##
## Args:
##     drop_pos (Vector3): Coordenadas onde o suprimento será depositado.
##
## Returns:
##     SupplyPickup: O suprimento instanciado caso sorteado, ou null.
func _try_spawn_supply_drop(drop_pos: Vector3) -> SupplyPickup:
	if supply_pickup_scene == null or stats_data == null:
		return null
	
	var roll: float = randf()
	if roll <= stats_data.supply_drop_chance:
		var pickup_instance: Node = supply_pickup_scene.instantiate()
		var pickup: SupplyPickup = pickup_instance as SupplyPickup
		if pickup != null:
			# Sorteia entre munição e combustível
			if randf() > 0.5:
				pickup.pickup_type = SupplyPickup.PickupType.FUEL_DRUM
			else:
				pickup.pickup_type = SupplyPickup.PickupType.AMMO_CRATE
			
			var root_parent: Node = parent_body.get_parent()
			if root_parent != null and root_parent.is_inside_tree():
				root_parent.add_child(pickup)
			elif parent_body.is_inside_tree():
				parent_body.add_sibling(pickup)
			else:
				parent_body.add_child(pickup)
			
			if pickup.is_inside_tree():
				pickup.global_position = drop_pos
				pickup.global_position.y = maxf(0.5, drop_pos.y)
			else:
				pickup.position = drop_pos
				pickup.position.y = maxf(0.5, drop_pos.y)
			return pickup
	return null


## Carrega projétil padrão baseado nas propriedades do stats_data.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _load_default_projectile() -> void:
	if stats_data != null and stats_data.is_homing_projectile:
		projectile_scene = load("res://scenes/weapons/projectile_enemy_sam_missile.tscn") as PackedScene
	else:
		projectile_scene = load("res://scenes/weapons/projectile_enemy_bullet.tscn") as PackedScene


## Instancia a explosao pesada de duas etapas no ponto de destruicao da entidade.
##
## Args:
##     epicenter (Vector3): Coordenadas espaciais da detonacao.
##
## Returns:
##     void
func _spawn_heavy_explosion(epicenter: Vector3) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null and parent_body != null and parent_body.get_parent() != null:
		root = parent_body.get_parent()
	if root == null:
		return
	
	var explosion_inst: Node3D = EXPLOSION_HEAVY_SCENE.instantiate() as Node3D
	if explosion_inst != null:
		root.add_child(explosion_inst)
		explosion_inst.global_position = epicenter


## Gera um circuito fechado de waypoints procedurais baseado na posicao de spawn.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _setup_default_patrol_circuit() -> void:
	if parent_body == null or stats_data == null:
		return
	var base_pos: Vector3 = parent_body.global_position if parent_body.is_inside_tree() else parent_body.position
	match stats_data.behavior:
		EnemyStatsData.BehaviorType.GROUND_PATROL:
			var r: float = 12.0
			patrol_waypoints = [
				base_pos + Vector3(r, 0.0, 0.0),
				base_pos + Vector3(0.0, 0.0, r),
				base_pos + Vector3(-r, 0.0, 0.0),
				base_pos + Vector3(0.0, 0.0, -r)
			]
		EnemyStatsData.BehaviorType.NAVAL_PATROL:
			var r_x: float = 24.0
			var r_z: float = 16.0
			patrol_waypoints = [
				base_pos + Vector3(r_x, 0.0, 0.0),
				base_pos + Vector3(0.0, 0.0, r_z),
				base_pos + Vector3(-r_x, 0.0, 0.0),
				base_pos + Vector3(0.0, 0.0, -r_z)
			]
