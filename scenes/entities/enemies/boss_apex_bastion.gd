## Entidade do Chefe da Missão: Canhoneiro Litorâneo Apex Bastion.
##
## Fragata autônoma modular com 4.000 HP no total:
## - Torreta de Proa (Canhão Duplo 76mm): 800 HP
## - Torreta de Popa (Lançador Quádruplo): 800 HP
## - Núcleo de Comando: 2.400 HP (invulnerável até ao menos 1 torreta cair)
## Fases:
## - Fase 1 (100% a 50% HP do Núcleo): Disparo de canhão duplo 76mm e minas navais.
## - Fase 2 (49% a 0% HP do Núcleo): CIWS em leque (60°) e salva de 4 mísseis teleguiados.
## Ao ser destruído, emite boss_defeated e mission_accomplished via EventBus.
class_name BossApexBastion
extends Node3D

signal phase_changed(phase_index: int)
signal boss_defeated()

@export var bow_turret: BossTurretModule
@export var stern_turret: BossTurretModule
@export var core_health: HealthComponent

@export var cannon_projectile_scene: PackedScene
@export var naval_mine_scene: PackedScene
@export var ciws_projectile_scene: PackedScene
@export var missile_projectile_scene: PackedScene

var current_phase: int = 1
var is_dead: bool = false

# Temporizadores de combate
var cannon_timer: float = 0.0
var mine_timer: float = 0.0
var ciws_timer: float = 0.0
var missile_timer: float = 0.0

var target_player: Node3D = null


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	
	if bow_turret == null:
		bow_turret = get_node_or_null("BowTurret") as BossTurretModule
	if stern_turret == null:
		stern_turret = get_node_or_null("SternTurret") as BossTurretModule
	if core_health == null:
		core_health = get_node_or_null("CoreHealth") as HealthComponent
	
	if core_health != null:
		core_health.max_health = 2400.0
		core_health.current_health = 2400.0
		core_health.entity_destroyed.connect(_on_core_destroyed)
	
	if cannon_projectile_scene == null:
		cannon_projectile_scene = load("res://scenes/weapons/projectile_boss_cannon.tscn") as PackedScene
	if naval_mine_scene == null:
		naval_mine_scene = load("res://scenes/entities/enemies/floating_naval_mine.tscn") as PackedScene
	if ciws_projectile_scene == null:
		ciws_projectile_scene = load("res://scenes/weapons/projectile_boss_ciws.tscn") as PackedScene
	if missile_projectile_scene == null:
		missile_projectile_scene = load("res://scenes/weapons/projectile_enemy_sam_missile.tscn") as PackedScene


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_update_target_player()
	
	# Verifica transição de fase
	if current_phase == 1 and core_health != null:
		var ratio: float = core_health.current_health / core_health.max_health
		if ratio <= 0.49:
			transition_to_phase(2)
	
	if current_phase == 1:
		_process_phase_1(delta)
	else:
		_process_phase_2(delta)


func _update_target_player() -> void:
	if target_player != null and is_instance_valid(target_player):
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var players: Array[Node] = tree.get_nodes_in_group("player")
	if not players.is_empty():
		target_player = players[0] as Node3D


## Encaminha danos genéricos sofridos pela entidade para a avaliação do reator central.
##
## Args:
##     amount (float): Quantidade de dano infligido.
##     source (Node3D): Entidade de origem do disparo.
##
## Returns:
##     void
func take_damage(amount: float, source: Node3D = null) -> void:
	damage_core(amount, source)


## Aplica dano ao núcleo central, respeitando invulnerabilidade caso as duas torretas estejam intactas.
func damage_core(amount: float, source: Node3D = null) -> void:
	if is_dead or core_health == null or amount <= 0.0:
		return
	
	# O núcleo só recebe dano após a queda de ao menos 1 das torretas
	var can_damage: bool = false
	if bow_turret != null and bow_turret.is_destroyed():
		can_damage = true
	elif stern_turret != null and stern_turret.is_destroyed():
		can_damage = true
	
	if can_damage:
		core_health.take_damage(amount, source)
		_check_phase_transition()


## Avalia se a proporção de vida atual do reator exige transição para a Fase 2.
func _check_phase_transition() -> void:
	if current_phase == 1 and core_health != null and core_health.max_health > 0.0:
		var ratio: float = core_health.current_health / core_health.max_health
		if ratio <= 0.49:
			transition_to_phase(2)


func transition_to_phase(new_phase: int) -> void:
	if current_phase == new_phase:
		return
	current_phase = new_phase
	
	if current_phase == 2:
		_activate_phase_2_visuals()
	
	phase_changed.emit(current_phase)
	if EventBus != null:
		EventBus.boss_phase_changed.emit("Apex Bastion", current_phase)


## Retrai as placas de blindagem do núcleo de comando e ativa o pulso emissivo do reator na Fase 2.
func _activate_phase_2_visuals() -> void:
	var left_armor: Node3D = get_node_or_null("CoreBridge/RetractableArmorLeft") as Node3D
	if left_armor != null:
		left_armor.position.x = -2.8
	var right_armor: Node3D = get_node_or_null("CoreBridge/RetractableArmorRight") as Node3D
	if right_armor != null:
		right_armor.position.x = 2.8
	
	var reactor: MeshInstance3D = get_node_or_null("CoreBridge/CoreReactorMesh") as MeshInstance3D
	if reactor != null and reactor.mesh != null:
		var mat: StandardMaterial3D = reactor.mesh.material as StandardMaterial3D
		if mat != null:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.28, 0.08, 1.0)
			mat.emission_energy_multiplier = 4.5



func _process_phase_1(delta: float) -> void:
	cannon_timer += delta
	mine_timer += delta
	
	# Canhão duplo a cada 2.5s (se a proa estiver viva)
	if cannon_timer >= 2.5:
		cannon_timer = 0.0
		if bow_turret == null or not bow_turret.is_destroyed():
			_fire_double_cannon()
	
	# Minas navais a cada 6.0s
	if mine_timer >= 6.0:
		mine_timer = 0.0
		_drop_naval_mine()


func _process_phase_2(delta: float) -> void:
	ciws_timer += delta
	missile_timer += delta
	
	# Pulso dinâmico do núcleo na Fase 2
	var reactor: MeshInstance3D = get_node_or_null("CoreBridge/CoreReactorMesh") as MeshInstance3D
	if reactor != null and reactor.mesh != null:
		var mat: StandardMaterial3D = reactor.mesh.material as StandardMaterial3D
		if mat != null and mat.emission_enabled:
			mat.emission_energy_multiplier = 4.2 + 1.6 * sin(float(Time.get_ticks_msec()) * 0.008)
	
	# CIWS leque a cada 3.0s
	if ciws_timer >= 3.0:
		ciws_timer = 0.0
		_fire_ciws_fan()
	
	# Salva de 4 mísseis a cada 7.0s
	if missile_timer >= 7.0:
		missile_timer = 0.0
		_fire_missile_salvo()



func _fire_double_cannon() -> void:
	if cannon_projectile_scene == null:
		return
	var boss_pos: Vector3 = global_position if is_inside_tree() else position
	var spawn_pos: Vector3 = bow_turret.global_position if (bow_turret != null and bow_turret.is_inside_tree()) else (boss_pos + Vector3(0, 2, -5))
	for offset_x in [-1.0, 1.0]:
		var proj: Projectile = cannon_projectile_scene.instantiate() as Projectile
		if proj != null:
			proj.source = self
			var fire_pos: Vector3 = spawn_pos + Vector3(offset_x, 0, 0)
			_add_projectile_to_scene(proj, fire_pos, _get_aim_direction(fire_pos))


func _drop_naval_mine() -> void:
	if naval_mine_scene == null:
		return
	var mine: FloatingNavalMine = naval_mine_scene.instantiate() as FloatingNavalMine
	if mine != null:
		var boss_pos: Vector3 = global_position if is_inside_tree() else position
		var base_pos: Vector3 = stern_turret.global_position if (stern_turret != null and stern_turret.is_inside_tree()) else (boss_pos + Vector3(0, 0, 5))
		var spawn_pos: Vector3 = base_pos + Vector3(randf_range(-3.0, 3.0), 0, randf_range(2.0, 6.0))
		spawn_pos.y = 0.2
		
		var parent_node: Node = get_parent()
		if parent_node != null and parent_node.is_inside_tree():
			parent_node.add_child(mine)
		elif is_inside_tree():
			add_sibling(mine)
		else:
			add_child(mine)
		
		if mine.is_inside_tree():
			mine.global_position = spawn_pos
		else:
			mine.position = spawn_pos


func _fire_ciws_fan() -> void:
	if ciws_projectile_scene == null:
		return
	var boss_pos: Vector3 = global_position if is_inside_tree() else position
	var origin: Vector3 = boss_pos + Vector3(0, 2.5, 0)
	var forward: Vector3 = _get_aim_direction(origin)
	
	# Leque de 60 graus (-30° a +30°) com 5 projéteis
	var angles: Array[float] = [-30.0, -15.0, 0.0, 15.0, 30.0]
	for deg in angles:
		var proj: Projectile = ciws_projectile_scene.instantiate() as Projectile
		if proj != null:
			proj.source = self
			var rad: float = deg_to_rad(deg)
			var rotated_dir: Vector3 = forward.rotated(Vector3.UP, rad).normalized()
			_add_projectile_to_scene(proj, origin, rotated_dir)


func _fire_missile_salvo() -> void:
	if missile_projectile_scene == null:
		return
	var boss_pos: Vector3 = global_position if is_inside_tree() else position
	var origin: Vector3 = stern_turret.global_position if (stern_turret != null and stern_turret.is_inside_tree()) else (boss_pos + Vector3(0, 2, 4))
	for i in range(4):
		var missile: Projectile = missile_projectile_scene.instantiate() as Projectile
		if missile != null:
			missile.source = self
			missile.is_homing = true
			missile.homing_turn_speed = 1.8
			missile.speed = 20.0
			missile.damage = 150.0
			if target_player != null:
				missile.homing_target = target_player
			var spread_pos: Vector3 = origin + Vector3((i - 1.5) * 0.8, 0.5, 0)
			_add_projectile_to_scene(missile, spread_pos, Vector3.UP.slerp(Vector3.FORWARD, 0.5))


func _add_projectile_to_scene(projectile: Projectile, pos: Vector3, dir: Vector3) -> void:
	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.is_inside_tree():
		parent_node.add_child(projectile)
	elif is_inside_tree():
		add_sibling(projectile)
	else:
		add_child(projectile)
	
	if projectile.is_inside_tree():
		projectile.global_position = pos
		if dir.length_squared() > 0.01:
			projectile.look_at(pos + dir, Vector3.UP)
	else:
		projectile.position = pos


func _get_aim_direction(from_pos: Vector3) -> Vector3:
	if target_player != null and is_instance_valid(target_player):
		var target_pos: Vector3 = target_player.global_position if target_player.is_inside_tree() else target_player.position
		return (target_pos - from_pos).normalized()
	if is_inside_tree():
		return -global_transform.basis.z.normalized()
	return -transform.basis.z.normalized()


func _on_core_destroyed() -> void:
	if is_dead:
		return
	is_dead = true
	boss_defeated.emit()
	if EventBus != null:
		EventBus.boss_defeated.emit("Apex Bastion")
		EventBus.mission_accomplished.emit()
	queue_free()
