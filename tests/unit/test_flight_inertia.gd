extends GutTest

## Bateria de testes unitarios para inercia, cinemática de voo e entidade PlayerHelicopter.

var controller: FlightMovementController


func before_each() -> void:
	controller = FlightMovementController.new()
	add_child_autofree(controller)


func test_controller_default_parameters() -> void:
	assert_almost_eq(controller.acceleration, 18.0, 0.01, "Aceleracao linear deve ser 18.0 m/s^2.")
	assert_almost_eq(controller.max_speed, 22.0, 0.01, "Velocidade maxima deve ser 22.0 m/s.")
	assert_almost_eq(controller.drag_deceleration, 7.5, 0.01, "Arrasto inercial deve ser 7.5 m/s^2.")
	assert_almost_eq(controller.cruise_altitude, 4.0, 0.01, "Altitude de cruzeiro deve ser 4.0 m.")
	assert_almost_eq(controller.hover_altitude, 0.8, 0.01, "Altitude de resgate/pairado deve ser 0.8 m.")
	assert_almost_eq(controller.altitude_transition_speed, 6.0, 0.01, "Velocidade vertical de transicao deve ser 6.0 m/s.")
	assert_almost_eq(controller.max_tilt_deg, 22.0, 0.01, "Inclinacao maxima deve ser 22.0 graus.")
	assert_almost_eq(controller.yaw_turn_speed, 8.0, 0.01, "Giro horizontal Yaw deve ser 8.0 rad/s.")


func test_acceleration_from_rest() -> void:
	var current_velocity: Vector3 = Vector3.ZERO
	var input_dir: Vector2 = Vector2(0.0, -1.0) # Move North
	var delta: float = 0.5
	
	var new_velocity: Vector3 = controller.compute_velocity(current_velocity, input_dir, false, 4.0, delta)
	# Em 0.5s a 18.0 m/s^2, velocidade deve atingir 9.0 m/s no eixo Z negativo
	assert_almost_eq(new_velocity.z, -9.0, 0.05, "A aeronave deve acelerar a 18.0 m/s^2 no eixo direcional.")
	assert_almost_eq(new_velocity.x, 0.0, 0.01, "Nao deve haver deslocamento lateral sem input em X.")


func test_speed_clamped_at_max_speed() -> void:
	var current_velocity: Vector3 = Vector3(0.0, 0.0, -20.0)
	var input_dir: Vector2 = Vector2(0.0, -1.0)
	var delta: float = 1.0 # 20 + 18 ultrapassaria 22.0
	
	var new_velocity: Vector3 = controller.compute_velocity(current_velocity, input_dir, false, 4.0, delta)
	assert_almost_eq(new_velocity.length(), 22.0, 0.01, "A velocidade horizontal nao deve exceder max_speed.")


func test_inertia_deceleration_distance_at_max_speed() -> void:
	# Simula soltura do direcional partindo da velocidade maxima de 22.0 m/s
	var vel: Vector3 = Vector3(0.0, 0.0, -22.0)
	var pos: Vector3 = Vector3.ZERO
	var delta: float = 1.0 / 60.0
	var elapsed: float = 0.0
	
	# Executa simulacao ate o repouso completo (esperado ~2.93 segundos e ~32.27 metros)
	while vel.length_squared() > 0.0001 and elapsed < 4.0:
		vel = controller.compute_velocity(vel, Vector2.ZERO, false, 4.0, delta)
		pos += vel * delta
		elapsed += delta
	
	assert_almost_eq(vel.length(), 0.0, 0.05, "A aeronave deve repousar completamente apos a inercia.")
	assert_true(elapsed > 2.7 and elapsed < 3.2, "O tempo de desaceleracao inercial deve ser aproximadamente 2.93s.")
	var distance_traveled: float = absf(pos.z)
	assert_true(distance_traveled > 30.0 and distance_traveled < 34.0, "A distancia de deslizamento inercial deve ser ~32.27m (medido: " + str(distance_traveled) + "m).")


func test_altitude_transition_cruise_to_hover() -> void:
	var current_y: float = 4.0
	var delta: float = 0.25 # Em 0.25s a 6.0 m/s, desce 1.5m -> 2.5m
	var vel: Vector3 = controller.compute_velocity(Vector3.ZERO, Vector2.ZERO, true, current_y, delta)
	
	var next_y: float = current_y + vel.y * delta
	assert_almost_eq(next_y, 2.5, 0.05, "A descida para hover (0.8m) deve ocorrer a 6.0 m/s.")


func test_altitude_transition_hover_to_cruise() -> void:
	var current_y: float = 0.8
	var delta: float = 0.25 # Em 0.25s a 6.0 m/s, sobe 1.5m -> 2.3m
	var vel: Vector3 = controller.compute_velocity(Vector3.ZERO, Vector2.ZERO, false, current_y, delta)
	
	var next_y: float = current_y + vel.y * delta
	assert_almost_eq(next_y, 2.3, 0.05, "A subida para cruise (4.0m) deve ocorrer a 6.0 m/s.")


func test_cosmetic_tilt_calculation() -> void:
	var max_accel_vec: Vector3 = Vector3(18.0, 0.0, -18.0)
	var tilt: Vector3 = controller.compute_cosmetic_tilt(max_accel_vec)
	var max_tilt_rad: float = deg_to_rad(22.0)
	
	assert_almost_eq(absf(tilt.z), max_tilt_rad, 0.02, "Roll cosmético deve inclinar no limite maximo de 22 graus.")
	assert_almost_eq(absf(tilt.x), max_tilt_rad, 0.02, "Pitch cosmético deve inclinar no limite maximo de 22 graus.")


func test_player_helicopter_scene_structure() -> void:
	var scene_res: PackedScene = load("res://scenes/entities/player/player_helicopter.tscn")
	assert_not_null(scene_res, "A cena player_helicopter.tscn deve existir.")
	
	var helicopter: CharacterBody3D = scene_res.instantiate() as CharacterBody3D
	assert_not_null(helicopter, "A entidade do helicóptero deve herdar de CharacterBody3D.")
	add_child_autofree(helicopter)
	
	# Camada 2 (Player_Air = 2) e Mascaras (1 + 4 + 8 + 32 + 128 = 173)
	assert_eq(helicopter.collision_layer, 2, "Camada de colisao deve ser 2 (Player_Air).")
	assert_eq(helicopter.collision_mask, 173, "Mascara de colisao deve incluir camadas 1, 3, 4, 6, 8 (total 173).")
	
	# Componentes filhos requeridos
	assert_not_null(helicopter.get_node_or_null("CollisionShape3D"), "Deve possuir colisor CollisionShape3D.")
	assert_not_null(helicopter.get_node_or_null("FlightMovementController"), "Deve conter o nó FlightMovementController.")
	assert_not_null(helicopter.get_node_or_null("HealthComponent"), "Deve conter o nó HealthComponent.")
	assert_not_null(helicopter.get_node_or_null("FuelComponent"), "Deve conter o nó FuelComponent.")
	assert_not_null(helicopter.get_node_or_null("WeaponManager"), "Deve conter o nó WeaponManager.")
	assert_not_null(helicopter.get_node_or_null("TargetScanner"), "Deve conter o nó TargetScanner.")
	assert_not_null(helicopter.get_node_or_null("HelicopterMeshContainer"), "Deve conter HelicopterMeshContainer.")
	
	# Hardpoints de armamento sob MuzzleMarkers
	var markers: Node3D = helicopter.get_node_or_null("HelicopterMeshContainer/MuzzleMarkers") as Node3D
	assert_not_null(markers, "Deve conter o nó agrupador MuzzleMarkers.")
	assert_not_null(markers.get_node_or_null("VulcanMuzzle"), "Muzzle Vulcan deve estar presente.")
	assert_not_null(markers.get_node_or_null("HydraPodLeft"), "Pod Hydra esquerdo deve estar presente.")
	assert_not_null(markers.get_node_or_null("HydraPodRight"), "Pod Hydra direito deve estar presente.")
	assert_not_null(markers.get_node_or_null("HellfireHardpoint"), "Hardpoint Hellfire deve estar presente.")


func test_autorotation_sequence_on_fuel_depleted() -> void:
	var scene_res: PackedScene = load("res://scenes/entities/player/player_helicopter.tscn")
	var helicopter: PlayerHelicopter = scene_res.instantiate() as PlayerHelicopter
	add_child_autofree(helicopter)
	
	assert_false(helicopter.is_autorotating, "Helicóptero nao deve iniciar em autorrotacao.")
	
	# Esgota o combustivel para disparar a autorrotacao
	helicopter.fuel_component.consume_active(100.0)
	assert_true(helicopter.is_autorotating, "Deve ativar estado is_autorotating apos pane seca.")
	
	# Simula o transcurso de 3 segundos de autorrotacao
	helicopter._physics_process(1.5)
	assert_true(helicopter.is_autorotating, "Deve continuar em autorrotacao antes de completar 3 segundos.")
	assert_false(helicopter.health_component.is_destroyed(), "Nao deve destruir antes dos 3 segundos.")
	
	helicopter._physics_process(1.5)
	assert_false(helicopter.is_autorotating, "Autorrotacao deve encerrar apos atingir 3 segundos.")
	assert_true(helicopter.health_component.is_destroyed(), "Aeronave deve colidir e ser destruida ao final da autorrotacao.")


func test_single_death_signal_with_fuel_exhaustion() -> void:
	var scene_res: PackedScene = load("res://scenes/entities/player/player_helicopter.tscn")
	var helicopter: PlayerHelicopter = scene_res.instantiate() as PlayerHelicopter
	add_child_autofree(helicopter)
	
	watch_signals(EventBus)
	
	# Aciona pane seca e completa os 3 segundos de autorrotacao
	helicopter.fuel_component.consume_active(100.0)
	helicopter._physics_process(3.0)
	
	assert_signal_emitted(EventBus, "player_died", "EventBus deve emitir player_died no desfecho da autorrotacao.")
	assert_signal_emit_count(EventBus, "player_died", 1, "EventBus deve emitir player_died exatamente uma vez.")
	
	var sig_args: Array = get_signal_parameters(EventBus, "player_died")
	assert_eq(sig_args[0], "fuel_exhaustion", "A causa de morte informada deve ser estritamente fuel_exhaustion.")


func test_aim_target_yaw_rotation() -> void:
	var scene_res: PackedScene = load("res://scenes/entities/player/player_helicopter.tscn")
	var helicopter: PlayerHelicopter = scene_res.instantiate() as PlayerHelicopter
	add_child_autofree(helicopter)
	helicopter.global_position = Vector3(0.0, 4.0, 0.0)
	helicopter.rotation = Vector3.ZERO
	
	# Alvo apontado para o Leste (+X = 20m)
	helicopter.set_aim_target(Vector3(20.0, 4.0, 0.0))
	assert_true(helicopter.has_aim_target, "has_aim_target deve ser true apos set_aim_target.")
	
	# Executa quadro fisico: deve rotacionar Yaw em direcao a -PI/2 (Leste)
	helicopter._physics_process(0.2)
	assert_true(helicopter.rotation.y < 0.0, "O angulo de Yaw deve girar em direcao ao alvo no quadrante Leste.")
	
	helicopter.clear_aim_target()
	assert_false(helicopter.has_aim_target, "has_aim_target deve ser false apos clear_aim_target.")
