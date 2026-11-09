## Testes unitarios de calculo matematico, aplicacao de boons e UI modal.
extends GutTest

var player: PlayerHelicopter
var boon_receiver: BoonReceiverComponent
var data_crate: DataCrate
var selection_ui: BoonSelectionUI


func before_each() -> void:
	player = preload("res://scenes/entities/player/player_helicopter.tscn").instantiate()
	add_child_autofree(player)
	boon_receiver = player.boon_receiver


func test_boon_receiver_initial_state() -> void:
	assert_not_null(boon_receiver, "BoonReceiverComponent deve estar presente no helicóptero.")
	assert_eq(boon_receiver.active_boons.size(), 0, "Nao deve haver boons ativos inicialmente.")
	assert_false(boon_receiver.auto_chaff_enabled, "Chaff automatico deve iniciar desabilitado.")
	assert_false(boon_receiver.try_trigger_chaff(), "Nao deve disparar Chaff se desabilitado.")


func test_apply_overclock_rotor_math() -> void:
	var boon: BoonData = preload("res://scripts/data/boon_overclock_rotor.tres")
	var initial_speed: float = player.flight_controller.max_speed
	var initial_accel: float = player.flight_controller.acceleration
	var initial_burn: float = player.fuel_component.active_burn_rate
	
	boon_receiver.apply_boon(boon)
	
	assert_almost_eq(player.flight_controller.max_speed, initial_speed * 1.15, 0.01, "Velocidade maxima deve aumentar em 15%.")
	assert_almost_eq(player.flight_controller.acceleration, initial_accel * 1.15, 0.01, "Aceleracao deve aumentar em 15%.")
	assert_almost_eq(player.fuel_component.active_burn_rate, initial_burn * 1.10, 0.01, "Consumo ativo deve aumentar em 10%.")
	assert_true(is_finite(player.flight_controller.max_speed), "Velocidade deve ser finita.")
	assert_gt(player.flight_controller.max_speed, 0.0, "Velocidade deve ser estritamente positiva.")


func test_apply_armor_piercing_ammo() -> void:
	var boon: BoonData = preload("res://scripts/data/boon_armor_piercing_ammo.tres")
	assert_false(player.weapon_manager.pierce_first_target, "Perfuracao deve iniciar inativa.")
	assert_eq(player.weapon_manager.structure_damage_bonus, 0.0, "Bonus de estrutura deve iniciar em zero.")
	
	boon_receiver.apply_boon(boon)
	
	assert_true(player.weapon_manager.pierce_first_target, "Perfuracao deve ser habilitada.")
	assert_almost_eq(player.weapon_manager.structure_damage_bonus, 0.25, 0.01, "Bonus contra estruturas deve ser +25%.")


func test_apply_high_power_winch() -> void:
	var boon: BoonData = preload("res://scripts/data/boon_high_power_winch.tres")
	assert_eq(player.cargo_component.boarding_duration, 2.0, "Tempo base de embarque deve ser 2.0s.")
	
	boon_receiver.apply_boon(boon)
	
	assert_almost_eq(player.cargo_component.boarding_duration, 1.1, 0.01, "Tempo de embarque deve reduzir para 1.1s.")
	assert_gt(player.cargo_component.boarding_duration, 0.0, "Tempo de embarque nao pode ser zero ou negativo.")


func test_apply_auxiliary_fuel_tanks() -> void:
	var boon: BoonData = preload("res://scripts/data/boon_auxiliary_fuel_tanks.tres")
	var initial_passive_burn: float = player.fuel_component.passive_burn_rate
	
	boon_receiver.apply_boon(boon)
	
	assert_eq(player.fuel_component.max_fuel, 180.0, "Capacidade do tanque deve subir para 180 unidades (150 base + 30).")
	assert_almost_eq(player.fuel_component.passive_burn_rate, initial_passive_burn * 0.85, 0.01, "Consumo passivo deve reduzir em 15%.")


func test_apply_chaff_flare_system_and_cooldown() -> void:
	var boon: BoonData = preload("res://scripts/data/boon_chaff_flare_system.tres")
	boon_receiver.apply_boon(boon)
	
	assert_true(boon_receiver.auto_chaff_enabled, "Sistema de Chaff deve estar habilitado.")
	assert_true(boon_receiver.try_trigger_chaff(), "Primeiro disparo de Chaff deve ter sucesso.")
	assert_false(boon_receiver.try_trigger_chaff(), "Disparo consecutivo imediato deve falhar por tempo de recarga.")
	
	# Simula passagem de tempo para liberar cooldown
	boon_receiver._process(12.1)
	assert_true(boon_receiver.try_trigger_chaff(), "Disparo de Chaff deve ter sucesso apos termino da recarga.")


func test_chaff_active_homing_missile_lock_break() -> void:
	var boon: BoonData = preload("res://scripts/data/boon_chaff_flare_system.tres")
	boon_receiver.apply_boon(boon)
	
	# Cria projetil hostil teleguiado
	var missile: Projectile = Projectile.new()
	missile.is_homing = true
	missile.homing_target = player
	add_child_autofree(missile)
	missile.add_to_group("homing_missiles")
	
	assert_true(missile.is_homing, "Missil deve iniciar teleguiado.")
	assert_not_null(missile.homing_target, "Alvo teleguiado do missil deve estar definido.")
	
	# Dispara contramedidas
	var triggered: bool = boon_receiver.try_trigger_chaff()
	assert_true(triggered, "Chaff deve disparar com sucesso.")
	
	# O travamento do missil deve ser quebrado
	assert_false(missile.is_homing, "O modo teleguiado do missil deve ser quebrado pelo Chaff.")
	assert_null(missile.homing_target, "O alvo do missil deve ser removido.")


func test_boons_math_safety_guards() -> void:
	var custom_boon: BoonData = BoonData.new()
	custom_boon.id = "infinite_edge"
	custom_boon.title = "Teste Extremo"
	custom_boon.target_system = BoonData.TargetSystem.FLIGHT
	custom_boon.operation = BoonData.OperationType.MULTIPLY
	custom_boon.target_property_name = "max_speed"
	custom_boon.value = 0.0 # Multiplicador zero
	
	boon_receiver.apply_boon(custom_boon)
	assert_true(is_finite(player.flight_controller.max_speed), "Velocidade deve permanecer finita.")
	assert_gt(player.flight_controller.max_speed, 0.0, "Velocidade nao deve ser zero para nao travar o motor de fisica.")


func test_reset_boons_restores_all_values() -> void:
	var initial_speed: float = player.flight_controller.max_speed
	var initial_fuel_cap: float = player.fuel_component.max_fuel
	var initial_winch: float = player.cargo_component.boarding_duration
	
	boon_receiver.apply_boon(preload("res://scripts/data/boon_overclock_rotor.tres"))
	boon_receiver.apply_boon(preload("res://scripts/data/boon_auxiliary_fuel_tanks.tres"))
	boon_receiver.apply_boon(preload("res://scripts/data/boon_high_power_winch.tres"))
	boon_receiver.apply_boon(preload("res://scripts/data/boon_chaff_flare_system.tres"))
	
	assert_ne(player.flight_controller.max_speed, initial_speed)
	assert_ne(player.fuel_component.max_fuel, initial_fuel_cap)
	assert_ne(player.cargo_component.boarding_duration, initial_winch)
	assert_true(boon_receiver.auto_chaff_enabled)
	
	boon_receiver.reset_boons()
	
	assert_almost_eq(player.flight_controller.max_speed, initial_speed, 0.001, "Velocidade deve retornar ao valor original.")
	assert_almost_eq(player.fuel_component.max_fuel, initial_fuel_cap, 0.001, "Tanque deve retornar ao valor original.")
	assert_almost_eq(player.cargo_component.boarding_duration, initial_winch, 0.001, "Guincho deve retornar ao valor original.")
	assert_false(boon_receiver.auto_chaff_enabled, "Chaff deve retornar a desabilitado.")
	assert_eq(boon_receiver.active_boons.size(), 0, "Lista de boons ativos deve ser esvaziada.")


func test_data_crate_destruction_emits_boons() -> void:
	data_crate = preload("res://scenes/roguelite/data_crate.tscn").instantiate()
	add_child_autofree(data_crate)
	
	watch_signals(EventBus)
	data_crate.take_damage(150.0)
	
	assert_signal_emitted(EventBus, "data_crate_opened", "Deve emitir data_crate_opened ao zerar a vida da caixa de dados.")
	var params: Array = get_signal_parameters(EventBus, "data_crate_opened")
	assert_not_null(params, "Parametros do sinal nao podem ser nulos.")
	assert_gt(params.size(), 0, "Deve conter parametros.")
	var boons_list: Array = params[0] as Array
	assert_eq(boons_list.size(), 3, "Deve sortear exatamente 3 boons.")


func test_boon_selection_ui_pauses_and_resumes() -> void:
	selection_ui = preload("res://scenes/roguelite/boon_selection_ui.tscn").instantiate()
	add_child_autofree(selection_ui)
	
	var boon_a: BoonData = preload("res://scripts/data/boon_overclock_rotor.tres")
	var boon_b: BoonData = preload("res://scripts/data/boon_high_power_winch.tres")
	var boon_c: BoonData = preload("res://scripts/data/boon_armor_piercing_ammo.tres")
	var boons_drawn: Array = [boon_a, boon_b, boon_c]
	
	selection_ui.open_selection(boons_drawn)
	
	assert_true(selection_ui.visible, "Modal de selecao deve ficar visivel.")
	assert_true(get_tree().paused, "A arvore de cena deve ser pausada na abertura do modal.")
	
	watch_signals(EventBus)
	selection_ui.select_option(1)
	
	assert_false(selection_ui.visible, "Modal deve se ocultar apos a escolha.")
	assert_false(get_tree().paused, "A arvore de cena deve despausar apos a confirmacao da escolha.")
	assert_signal_emitted(EventBus, "boon_applied", "Deve emitir boon_applied no EventBus.")
	var params: Array = get_signal_parameters(EventBus, "boon_applied")
	assert_not_null(params, "Parametros do sinal nao podem ser nulos.")
	assert_eq(params[0], boon_b.id, "Parametro deve conter o ID do boon selecionado.")
