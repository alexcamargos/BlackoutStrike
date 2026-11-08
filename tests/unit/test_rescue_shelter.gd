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


func test_shelter_collapse_prioritizes_dedicated_civilian_container() -> void:
	var dedicated_container: Node3D = Node3D.new()
	dedicated_container.add_to_group("civilian_container")
	add_child_autofree(dedicated_container)
	
	var shelter: RescueShelter = shelter_scene.instantiate() as RescueShelter
	add_child_autofree(shelter)
	shelter.global_position = Vector3(0.0, 0.0, 0.0)
	
	shelter.take_damage(300.0)
	
	var in_dedicated: Array[Civilian] = []
	for child in dedicated_container.get_children():
		if child is Civilian:
			in_dedicated.append(child as Civilian)
	
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
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	watch_signals(EventBus)
	
	# Simula detonacao em area no raio do projetil
	rocket._apply_area_damage(rocket.global_position, rocket.damage)
	
	assert_true(civ.is_dead, "O civil deve perecer ao ser atingido por raio de explosao de foguete.")
