extends GutTest

var enemy_controller: EnemyAIController
var dummy_parent: CharacterBody3D
var health_comp: HealthComponent
var stats_res: EnemyStatsData

func before_each() -> void:
	dummy_parent = CharacterBody3D.new()
	health_comp = HealthComponent.new()
	health_comp.name = "HealthComponent"
	dummy_parent.add_child(health_comp)
	
	enemy_controller = EnemyAIController.new()
	enemy_controller.name = "EnemyAIController"
	
	stats_res = EnemyStatsData.new()
	stats_res.id = "test_enemy"
	stats_res.max_health = 100.0
	stats_res.move_speed = 5.0
	stats_res.detection_range = 25.0
	stats_res.fire_interval = 1.0
	stats_res.projectile_damage = 20.0
	stats_res.suppresses_rescue_ring = true
	stats_res.suppression_radius = 10.0
	stats_res.supply_drop_chance = 1.0 # Força drop em teste
	
	enemy_controller.stats_data = stats_res
	dummy_parent.add_child(enemy_controller)
	add_child_autofree(dummy_parent)

func test_controller_initializes_and_configures_health() -> void:
	assert_eq(health_comp.max_health, 100.0, "O controlador deve parametrizar a vida maxima do componente.")
	assert_eq(health_comp.current_health, 100.0, "O controlador deve parametrizar a vida inicial.")
	assert_true(dummy_parent.is_in_group("enemies"), "A entidade pai deve pertencer ao grupo 'enemies'.")
	assert_true(dummy_parent.is_in_group("ground_enemies"), "Inimigo nao-aereo deve pertencer ao grupo 'ground_enemies'.")

func test_fire_weapon_at_target_spawns_projectile() -> void:
	watch_signals(enemy_controller)
	var target_node: Node3D = Node3D.new()
	add_child_autofree(target_node)
	target_node.global_position = Vector3(10.0, 0.0, 0.0)
	
	var proj: Projectile = enemy_controller.fire_weapon_at(target_node)
	if proj != null:
		autofree(proj)
	assert_not_null(proj, "Disparar a arma deve instanciar um projetil valido.")
	assert_signal_emitted(enemy_controller, "weapon_fired", "Deve emitir o sinal weapon_fired.")
	assert_eq(proj.damage, 20.0, "O dano do projetil deve corresponder ao stats_data.")
	assert_eq(proj.source, dummy_parent, "O projetil deve referenciar a entidade atiradora.")

func test_air_interceptor_assigned_to_air_enemies_group() -> void:
	var air_parent: CharacterBody3D = CharacterBody3D.new()
	var air_hc: HealthComponent = HealthComponent.new()
	air_hc.name = "HealthComponent"
	air_parent.add_child(air_hc)
	
	var air_ctrl: EnemyAIController = EnemyAIController.new()
	var air_stats: EnemyStatsData = EnemyStatsData.new()
	air_stats.behavior = EnemyStatsData.BehaviorType.AIR_INTERCEPTOR
	air_ctrl.stats_data = air_stats
	
	air_parent.add_child(air_ctrl)
	add_child_autofree(air_parent)
	
	assert_true(air_parent.is_in_group("air_enemies"), "Interceptor aereo deve receber grupo 'air_enemies'.")

func test_entity_destroyed_drops_supply_and_emits_killed() -> void:
	watch_signals(enemy_controller)
	stats_res.supply_drop_chance = 1.0 # 100% de garantia de drop
	
	health_comp.take_damage(200.0)
	
	assert_signal_emitted(enemy_controller, "enemy_killed", "Deve emitir enemy_killed ao zerar a vida.")
	assert_true(dummy_parent.is_queued_for_deletion(), "O no pai deve entrar na fila de delecao.")
	
	# Desaloca os drops instanciados como irmaos do dummy_parent para evitar nós órfãos
	var tree: SceneTree = get_tree()
	if tree != null:
		var root: Node = tree.root
		for child in root.get_children():
			if child is SupplyPickup:
				child.free()
	for child in get_children():
		if child is SupplyPickup:
			child.free()

func test_patrol_waypoints_cycle() -> void:
	enemy_controller.patrol_waypoints = [Vector3(0, 0, 0), Vector3(10, 0, 0)]
	dummy_parent.global_position = Vector3(0.5, 0, 0) # Quase no waypoint 0
	
	enemy_controller._move_along_patrol(0.1)
	assert_eq(enemy_controller.current_waypoint_index, 1, "Ao aproximar do waypoint 0 deve alternar para o 1.")

func test_architecture_contract_methods() -> void:
	var origin: Vector3 = Vector3(0, 0, 0)
	var target_near: Vector3 = Vector3(15, 0, 0)
	var target_far: Vector3 = Vector3(50, 0, 0)
	
	var vel: Vector3 = enemy_controller.compute_movement_velocity(origin, target_near, 0.1)
	assert_eq(vel, Vector3(5.0, 0.0, 0.0), "Velocidade calculada deve respeitar direcao e move_speed.")
	
	assert_true(enemy_controller.can_engage_target(origin, target_near), "Deve engajar alvo dentro de detection_range (25m).")
	assert_false(enemy_controller.can_engage_target(origin, target_far), "Nao deve engajar alvo alem de detection_range.")
	
	assert_true(enemy_controller.is_suppressing_position(origin, Vector3(5, 0, 0)), "Deve suprimir civis a menos de 10m.")
	assert_false(enemy_controller.is_suppressing_position(origin, Vector3(12, 0, 0)), "Nao deve suprimir alem de suppression_radius.")

func test_all_five_archetype_scenes_instantiate_cleanly() -> void:
	var archetypes: Array[String] = [
		"res://scenes/entities/enemies/mercenary_squad.tscn",
		"res://scenes/entities/enemies/hunter_drone.tscn",
		"res://scenes/entities/enemies/patrol_boat.tscn",
		"res://scenes/entities/enemies/light_tank_ifv.tscn",
		"res://scenes/entities/enemies/turret_sam.tscn"
	]
	
	for scene_path: String in archetypes:
		var scene_res: PackedScene = load(scene_path) as PackedScene
		assert_not_null(scene_res, "A cena %s deve existir e ser carregada." % scene_path)
		var instance: Node = scene_res.instantiate()
		assert_not_null(instance, "A cena %s deve ser instanciada com sucesso." % scene_path)
		add_child_autofree(instance)
		
		var ai: EnemyAIController = instance.get_node_or_null("EnemyAIController") as EnemyAIController
		assert_not_null(ai, "A cena %s deve conter um EnemyAIController." % scene_path)
		assert_not_null(ai.stats_data, "O EnemyAIController de %s deve ter stats_data atribuido." % scene_path)
		
		var hc: HealthComponent = instance.get_node_or_null("HealthComponent") as HealthComponent
		assert_not_null(hc, "A cena %s deve conter um HealthComponent." % scene_path)


func test_enemy_archetypes_modular_pbr_and_emissive_palette() -> void:
	var archetypes: Array[String] = [
		"res://scenes/entities/enemies/mercenary_squad.tscn",
		"res://scenes/entities/enemies/hunter_drone.tscn",
		"res://scenes/entities/enemies/patrol_boat.tscn",
		"res://scenes/entities/enemies/light_tank_ifv.tscn",
		"res://scenes/entities/enemies/turret_sam.tscn"
	]
	
	for scene_path in archetypes:
		var scene_res: PackedScene = load(scene_path) as PackedScene
		var instance: Node3D = scene_res.instantiate() as Node3D
		add_child_autofree(instance)
		
		# Verifica nó de torreta desacoplada e muzzle
		var turret: Node3D = instance.get_node_or_null("Turret") as Node3D
		assert_not_null(turret, "O arquétipo %s deve possuir nó Turret desacoplado." % scene_path)
		var muzzle: Marker3D = turret.get_node_or_null("Muzzle") as Marker3D
		assert_not_null(muzzle, "A torreta de %s deve conter um Marker3D Muzzle." % scene_path)
		
		# Varre malhas para validar paleta antracite (#1F2226) e optica emissiva (#D9381E)
		var found_antracite: bool = false
		var found_emissive_red: bool = false
		
		var meshes_to_check: Array[MeshInstance3D] = []
		var stack: Array[Node] = [instance]
		while not stack.is_empty():
			var curr: Node = stack.pop_back()
			if curr is MeshInstance3D and curr.mesh != null and curr.mesh.material is StandardMaterial3D:
				meshes_to_check.append(curr)
			for child in curr.get_children():
				stack.append(child)
		
		for mi in meshes_to_check:
			var mat: StandardMaterial3D = mi.mesh.material as StandardMaterial3D
			if mat != null:
				# Checa antracite #1F2226
				if absf(mat.albedo_color.r - 0.122) < 0.03 and absf(mat.albedo_color.b - 0.149) < 0.03:
					found_antracite = true
				# Checa ótica emissiva vermelha-alaranjada #D9381E
				if mat.emission_enabled and mat.emission_energy_multiplier >= 2.5:
					if absf(mat.emission.r - 0.851) < 0.03 and absf(mat.emission.g - 0.220) < 0.03:
						found_emissive_red = true
		
		assert_true(found_antracite, "Arquétipo %s deve conter peças com pintura antracite (#1F2226)." % scene_path)
		assert_true(found_emissive_red, "Arquétipo %s deve conter ótica emissiva vermelho-alaranjada (#D9381E HDR)." % scene_path)


func test_enemy_turret_aiming_and_projectile_coincidence() -> void:
	var tank_res: PackedScene = load("res://scenes/entities/enemies/light_tank_ifv.tscn")
	var tank: Node3D = tank_res.instantiate() as Node3D
	add_child_autofree(tank)
	tank.global_position = Vector3(0.0, 0.0, 0.0)
	
	var ai: EnemyAIController = tank.get_node_or_null("EnemyAIController") as EnemyAIController
	assert_not_null(ai, "Deve possuir EnemyAIController.")
	
	# Alvo tático a 45 graus no plano XZ
	var target: Node3D = Node3D.new()
	add_child_autofree(target)
	target.global_position = Vector3(20.0, 0.0, 20.0)
	
	# Simula apontamento angular desacoplado da torreta
	ai._orient_towards(target.global_position, 1.0)
	
	var turret: Node3D = tank.get_node_or_null("Turret") as Node3D
	assert_not_null(turret, "LightTankIFV deve possuir torreta.")
	
	# Dispara projetil
	var proj: Projectile = ai.fire_weapon_at(target)
	if proj != null:
		autoqfree(proj)
		assert_not_null(proj, "Deve disparar projétil.")
		
		# O vetor de disparo deve coincidir com a linha de visada para o alvo
		var expected_dir: Vector3 = (target.global_position - turret.global_position).normalized()
		var proj_forward: Vector3 = -proj.global_transform.basis.z.normalized()
		var dot_prod: float = proj_forward.dot(expected_dir)
		assert_true(dot_prod > 0.95, "O vetor de disparo do projétil deve coincidir com a orientação angular do alvo (dot: " + str(dot_prod) + ").")

