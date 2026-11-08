extends GutTest

## Bateria de testes unitarios para abrigos destrutíveis e civis (TASK-030).

var shelter_scene: PackedScene = preload("res://scenes/entities/npcs/rescue_shelter.tscn")
var civilian_scene: PackedScene = preload("res://scenes/entities/npcs/civilian.tscn")
var hydra_projectile_scene: PackedScene = preload("res://scenes/weapons/projectile_hydra.tscn")


func before_each() -> void:
	if GameState != null:
		GameState.start_new_run()


func test_shelter_initial_state() -> void:
	var shelter: RescueShelter = shelter_scene.instantiate() as RescueShelter
	add_child_autofree(shelter)
	
	assert_not_null(shelter, "A cena de RescueShelter deve instanciar corretamente.")
	assert_true(shelter.is_in_group("structures"), "O abrigo deve pertencer ao grupo 'structures'.")
	assert_eq(shelter.collision_layer, 4, "O abrigo deve residir na Camada 3 (Enemies_Ground / bitmask 4).")
	assert_not_null(shelter.health_component, "O abrigo deve possuir HealthComponent.")
	assert_almost_eq(shelter.health_component.max_health, 300.0, 0.001, "Integridade maxima inicial deve ser 300.0 HP.")
	assert_almost_eq(shelter.health_component.current_health, 300.0, 0.001, "Integridade atual inicial deve ser 300.0 HP.")


func test_shelter_takes_damage_without_collapsing() -> void:
	var shelter: RescueShelter = shelter_scene.instantiate() as RescueShelter
	add_child_autofree(shelter)
	
	shelter.take_damage(120.0)
	assert_almost_eq(shelter.health_component.current_health, 180.0, 0.01, "Dano aplicado deve reduzir a saude da estrutura.")
	assert_false(shelter.is_collapsed, "O abrigo nao deve colapsar com HP residual.")


func test_shelter_collapse_emits_event_and_spawns_survivors() -> void:
	var parent_container: Node3D = Node3D.new()
	add_child_autofree(parent_container)
	
	var shelter: RescueShelter = shelter_scene.instantiate() as RescueShelter
	parent_container.add_child(shelter)
	shelter.global_position = Vector3(10.0, 0.0, 20.0)
	
	watch_signals(EventBus)
	
	shelter.take_damage(300.0)
	
	assert_signal_emitted(EventBus, "shelter_destroyed", "EventBus.shelter_destroyed deve ser emitido.")
	var destroyed_params: Array = get_signal_parameters(EventBus, "shelter_destroyed")
	assert_eq(destroyed_params.size(), 2, "shelter_destroyed deve emitir 2 parametros.")
	assert_eq(destroyed_params[0], Vector3(10.0, 0.0, 20.0), "Coordenada deve bater com a posicao do abrigo.")
	assert_eq(destroyed_params[1], 4, "Quantidade de sobreviventes deve ser 4.")
	
	var spawned_civilians: Array[Civilian] = []
	for child in parent_container.get_children():
		if child is Civilian:
			spawned_civilians.append(child as Civilian)
	
	assert_eq(spawned_civilians.size(), 4, "Exatamente 4 instancias de civis devem ser geradas.")
	
	for civ in spawned_civilians:
		var dist: float = civ.global_position.distance_to(Vector3(10.0, 0.0, 20.0))
		assert_almost_eq(dist, 2.5, 0.1, "Cada civil deve ser instanciado no raio de dispersao de 2.5m.")
	
	for child in parent_container.get_children():
		autoqfree(child)


func test_shelter_collapse_prioritizes_dedicated_civilian_container() -> void:
	var dedicated_container: Node3D = Node3D.new()
	dedicated_container.add_to_group("civilian_container")
	add_child_autofree(dedicated_container)
	
	var shelter_parent: Node3D = Node3D.new()
	add_child_autofree(shelter_parent)
	
	var shelter: RescueShelter = shelter_scene.instantiate() as RescueShelter
	shelter_parent.add_child(shelter)
	shelter.global_position = Vector3(0.0, 0.0, 0.0)
	
	shelter.take_damage(300.0)
	
	var in_dedicated: Array[Civilian] = []
	for child in dedicated_container.get_children():
		if child is Civilian:
			in_dedicated.append(child as Civilian)
		autoqfree(child)
	
	for child in shelter_parent.get_children():
		autoqfree(child)
	
	assert_eq(in_dedicated.size(), 4, "Civis liberados devem ser anexados ao container dedicado quando presente.")



func test_civilian_initial_state() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	
	assert_not_null(civ, "A cena de Civilian deve instanciar corretamente.")
	assert_true(civ.is_in_group("civilians"), "O civil deve pertencer ao grupo 'civilians'.")
	assert_eq(civ.collision_layer, 64, "O civil deve residir na Camada 7 (Civilians / bitmask 64).")
	assert_not_null(civ.health_component, "O civil deve possuir HealthComponent.")
	assert_almost_eq(civ.health_component.max_health, 30.0, 0.001, "Integridade maxima do civil deve ser 30.0 HP.")
	assert_almost_eq(civ.health_component.current_health, 30.0, 0.001, "Integridade atual do civil deve ser 30.0 HP.")


func test_civilian_death_emits_civilian_killed_signal() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	
	watch_signals(EventBus)
	
	civ.take_damage(30.0)
	
	assert_true(civ.is_dead, "O civil deve ser marcado como morto.")
	assert_false(civ.is_rescued, "O civil morto nao deve ter status de resgatado.")
	assert_signal_emitted(EventBus, "civilian_killed", "EventBus.civilian_killed deve ser emitido ao morrer.")


func test_civilian_vulnerable_to_explosive_projectile_damage() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	civ.global_position = Vector3(5.0, 0.0, 0.0)
	
	# Instancia projetil explosivo Hydra nas proximidades (raio de 3.0m)
	var rocket: Projectile = hydra_projectile_scene.instantiate() as Projectile
	add_child_autofree(rocket)
	rocket.global_position = Vector3(6.0, 0.0, 0.0)
	
	# Aguarda sincronizacao do espaco fisico no PhysicsServer3D
	await wait_physics_frames(2)
	
	watch_signals(EventBus)
	
	# Simula detonacao em area no raio do projetil
	rocket._apply_area_damage(rocket.global_position, rocket.damage)
	
	assert_true(civ.is_dead, "O civil deve perecer ao ser atingido por raio de explosao de foguete.")


func test_civilian_high_visibility_model() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	
	# Verifica malhas do modelo de cientista/engenheiro de alta visibilidade
	var torso: MeshInstance3D = civ.get_node_or_null("ModelContainer/Torso") as MeshInstance3D
	assert_not_null(torso, "Civil deve possuir malha de torso.")
	var torso_mat: StandardMaterial3D = torso.mesh.material as StandardMaterial3D
	assert_not_null(torso_mat, "Torso deve conter material PBR.")
	assert_almost_eq(torso_mat.albedo_color.r, 0.96, 0.05, "Uniforme deve ser laranja de alta visibilidade.")
	
	var vest: MeshInstance3D = civ.get_node_or_null("ModelContainer/Torso/ReflectiveVest") as MeshInstance3D
	assert_not_null(vest, "Civil deve possuir faixa refletiva de seguranca.")
	
	var hardhat: MeshInstance3D = civ.get_node_or_null("ModelContainer/Head/SafetyHardhat") as MeshInstance3D
	assert_not_null(hardhat, "Civil deve possuir capacete de seguranca.")
	var hardhat_mat: StandardMaterial3D = hardhat.mesh.material as StandardMaterial3D
	assert_almost_eq(hardhat_mat.albedo_color.r, 1.0, 0.05, "Capacete deve ser amarelo-seguranca.")


func test_shelter_reinforced_concrete_model_and_debris_instantiation() -> void:
	var debris_script: GDScript = preload("res://scenes/entities/npcs/shelter_debris.gd")
	var parent_container: Node3D = Node3D.new()
	add_child_autofree(parent_container)
	
	var shelter: RescueShelter = shelter_scene.instantiate() as RescueShelter
	parent_container.add_child(shelter)
	shelter.global_position = Vector3(0.0, 0.0, 0.0)
	
	# Verifica materiais de concreto reforcado e porta blindada
	var walls: MeshInstance3D = shelter.get_node_or_null("ModelContainer/BunkerWalls") as MeshInstance3D
	assert_not_null(walls, "Abrigo deve conter paredes de concreto.")
	var concrete_mat: StandardMaterial3D = walls.mesh.material as StandardMaterial3D
	assert_true(concrete_mat.roughness >= 0.8, "Concreto reforcado deve possuir alta rugosidade (>= 0.8).")
	
	var door: MeshInstance3D = shelter.get_node_or_null("ModelContainer/BlastDoor") as MeshInstance3D
	assert_not_null(door, "Abrigo deve conter porta blindada.")
	
	# Destroi o abrigo
	shelter.take_damage(300.0)
	
	# Verifica que pecas de escombros ShelterDebris foram instanciadas no container pai
	var debris_count: int = 0
	for child in parent_container.get_children():
		if child is RigidBody3D and child.get_script() == debris_script:
			debris_count += 1
			# Assegura que escombros nao colidem com civis (collision_layer = 0)
			assert_eq(child.collision_layer, 0, "Escombros nao devem colidir com a camada de civis (layer deve ser 0).")
			assert_eq(child.collision_mask, 1, "Escombros devem colidir apenas com World_Static.")
		autoqfree(child)
	
	assert_true(debris_count >= 4, "A destruicao do abrigo deve instanciar pecas fragmentadas de escombros (contado: %d)." % debris_count)


