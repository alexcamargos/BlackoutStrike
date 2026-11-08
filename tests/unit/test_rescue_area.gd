extends GutTest

## Bateria de testes unitarios para deteccao, supressao e anel de resgate (RescueSensorArea).

var rescue_sensor: RescueSensorArea
var cargo: CargoComponent
var civilian_scene: PackedScene = preload("res://scenes/entities/npcs/civilian.tscn")


func before_each() -> void:
	cargo = CargoComponent.new()
	cargo.max_capacity = 5
	cargo.current_occupants = 0
	add_child_autofree(cargo)
	
	rescue_sensor = RescueSensorArea.new()
	rescue_sensor.max_rescue_altitude = 1.2
	rescue_sensor.max_rescue_speed = 4.0
	rescue_sensor.suppression_radius = 10.0
	rescue_sensor.boarding_duration = 2.0
	rescue_sensor.cargo_component = cargo
	add_child_autofree(rescue_sensor)


func test_rescue_progress_advances_when_hovering_low() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	civ.global_position = Vector3(0.0, 0.0, 0.0)
	
	rescue_sensor.global_position = Vector3(0.0, 1.0, 0.0)
	rescue_sensor._on_body_entered(civ)
	
	rescue_sensor.step(1.0)
	assert_almost_eq(rescue_sensor.get_boarding_progress(), 0.5, 0.01, "O progresso deve avancar 50% em 1.0s de um total de 2.0s.")
	assert_false(rescue_sensor.is_suppressed, "Nao deve estar suprimido sem inimigos proximos.")
	assert_true(rescue_sensor.rescue_ring_mesh.visible, "O anel holografico deve ficar visivel durante o pairamento.")


func test_rescue_progress_resets_if_altitude_exceeds_threshold() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	civ.global_position = Vector3(0.0, 0.0, 0.0)
	
	rescue_sensor.global_position = Vector3(0.0, 1.0, 0.0)
	rescue_sensor._on_body_entered(civ)
	rescue_sensor.step(1.0)
	assert_almost_eq(rescue_sensor.get_boarding_progress(), 0.5, 0.01, "Progresso inicial em 50%.")
	
	# Sobe alem do teto de resgate (Y = 2.5m > 1.2m)
	rescue_sensor.global_position = Vector3(0.0, 2.5, 0.0)
	rescue_sensor.step(0.1)
	
	assert_eq(rescue_sensor.get_boarding_progress(), 0.0, "Subir acima de 1.2m deve resetar o progresso para zero.")
	assert_false(rescue_sensor.rescue_ring_mesh.visible, "O anel holografico deve ser ocultado ao subir.")


func test_rescue_suppressed_by_ground_enemy_within_10m() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	civ.global_position = Vector3(0.0, 0.0, 0.0)
	
	# Instancia inimigo terrestre a 7 metros do civil (raio <= 10m)
	var enemy: Node3D = Node3D.new()
	add_child_autofree(enemy)
	enemy.add_to_group("enemies")
	enemy.global_position = Vector3(7.0, 0.0, 0.0)
	
	rescue_sensor.global_position = Vector3(0.0, 1.0, 0.0)
	rescue_sensor._on_body_entered(civ)
	
	watch_signals(EventBus)
	
	rescue_sensor.step(0.1)
	assert_true(rescue_sensor.is_suppressed, "O anel deve entrar em estado de supressao.")
	assert_signal_emitted(EventBus, "rescue_zone_suppressed", "Deve emitir EventBus.rescue_zone_suppressed.")
	
	# Tenta avancar mais tempo sob supressao
	rescue_sensor.step(1.0)
	assert_eq(rescue_sensor.get_boarding_progress(), 0.0, "O cronometro de embarque deve congelar sob supressao.")


func test_rescue_resumes_and_boards_when_enemy_cleared() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	civ.global_position = Vector3(0.0, 0.0, 0.0)
	
	var enemy: Node3D = Node3D.new()
	add_child_autofree(enemy)
	enemy.add_to_group("enemies")
	enemy.global_position = Vector3(7.0, 0.0, 0.0)
	
	rescue_sensor.global_position = Vector3(0.0, 1.0, 0.0)
	rescue_sensor._on_body_entered(civ)
	
	watch_signals(EventBus)
	
	rescue_sensor.step(0.1)
	assert_true(rescue_sensor.is_suppressed, "Deve estar suprimido inicialmente.")
	
	# Elimina o inimigo do perimetro
	enemy.remove_from_group("enemies")
	
	rescue_sensor.step(0.1)
	assert_false(rescue_sensor.is_suppressed, "A supressao deve cessar com o perimetro limpo.")
	
	# Completa o ciclo de 2.0s
	rescue_sensor.step(2.0)
	assert_eq(cargo.current_occupants, 1, "O civil deve ter embarcado na cabine.")
	assert_true(civ.is_dead, "A entidade do civil resgatado deve ser desalocada.")


func test_rescue_blocked_when_cabin_is_full() -> void:
	var civ: Civilian = civilian_scene.instantiate() as Civilian
	add_child_autofree(civ)
	civ.global_position = Vector3(0.0, 0.0, 0.0)
	
	cargo.current_occupants = 5 # Lota a cabine
	
	rescue_sensor.global_position = Vector3(0.0, 1.0, 0.0)
	rescue_sensor._on_body_entered(civ)
	
	rescue_sensor.step(1.0)
	assert_eq(rescue_sensor.get_boarding_progress(), 0.0, "Nao deve iniciar embarque com cabine lotada.")
	assert_false(rescue_sensor.rescue_ring_mesh.visible, "O anel deve permanecer inativo com a cabine lotada.")
