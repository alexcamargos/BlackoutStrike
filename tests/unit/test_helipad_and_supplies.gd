extends GutTest

## Bateria de testes unitarios para Heliponto Aliado e Suprimentos de Campo (TASK-032).

var helipad_scene: PackedScene = preload("res://scenes/environment/ally_helipad.tscn")
var supply_scene: PackedScene = preload("res://scenes/roguelite/supply_pickup.tscn")
var player_scene: PackedScene = preload("res://scenes/entities/player/player_helicopter.tscn")


func before_each() -> void:
	if MetaProgression != null:
		MetaProgression.reset_state()
	if GameState != null:
		GameState.start_new_run()


func test_helipad_unloads_passengers_and_awards_meta_tokens() -> void:
	var helipad: AllyBaseHelipad = helipad_scene.instantiate() as AllyBaseHelipad
	add_child_autofree(helipad)
	helipad.global_position = Vector3(0.0, 0.0, 0.0)
	
	var player: PlayerHelicopter = player_scene.instantiate() as PlayerHelicopter
	add_child_autofree(player)
	player.global_position = Vector3(0.0, 1.0, 0.0) # Altitude valida de pouso (1.0m <= 1.2m)
	
	# Preenche a cabine com 4 sobreviventes
	player.cargo_component.current_occupants = 4
	
	helipad._on_body_entered(player)
	
	watch_signals(EventBus)
	watch_signals(helipad)
	
	helipad.step(0.1)
	
	assert_eq(player.cargo_component.current_occupants, 0, "A cabine deve esvaziar completamente apos o pouso.")
	assert_eq(MetaProgression.personnel_tokens, 4, "MetaProgression deve receber 4 Personnel Tokens.")
	assert_eq(GameState.rescued_in_current_run, 4, "GameState deve registrar 4 civis extraidos na run.")
	assert_signal_emitted(EventBus, "civilian_extracted", "EventBus.civilian_extracted deve ser emitido.")
	assert_signal_emitted(helipad, "civilians_unloaded_at_base", "O heliponto deve emitir civilians_unloaded_at_base.")


func test_helipad_repairs_and_refuels_landed_helicopter() -> void:
	var helipad: AllyBaseHelipad = helipad_scene.instantiate() as AllyBaseHelipad
	add_child_autofree(helipad)
	helipad.global_position = Vector3(0.0, 0.0, 0.0)
	
	var player: PlayerHelicopter = player_scene.instantiate() as PlayerHelicopter
	add_child_autofree(player)
	player.global_position = Vector3(0.0, 0.8, 0.0) # Pousado
	
	# Reduz integridade e combustivel
	player.health_component.current_health = 800.0
	player.fuel_component.current_fuel = 50.0
	
	helipad._on_body_entered(player)
	
	# Simula 1.0 segundo de permanencia atracado
	helipad.step(1.0)
	
	# Taxa de reparo: 40 HP/s -> 800 + 40 = 840
	assert_almost_eq(player.health_component.current_health, 840.0, 0.1, "Blindagem deve regenerar a 40.0 HP/s.")
	# Taxa de combustivel: 15 Fuel/s -> 50 + 15 = 65
	assert_almost_eq(player.fuel_component.current_fuel, 65.0, 0.1, "Combustivel deve abastecer a 15.0 u/s.")
	assert_true(helipad.is_servicing, "O heliponto deve estar em estado de atendimento ativo.")


func test_helipad_aborts_service_when_helicopter_ascends() -> void:
	var helipad: AllyBaseHelipad = helipad_scene.instantiate() as AllyBaseHelipad
	add_child_autofree(helipad)
	
	var player: PlayerHelicopter = player_scene.instantiate() as PlayerHelicopter
	add_child_autofree(player)
	player.global_position = Vector3(0.0, 3.0, 0.0) # Voo alto (> 1.2m)
	player.health_component.current_health = 500.0
	
	helipad._on_body_entered(player)
	helipad.step(1.0)
	
	assert_false(helipad.is_servicing, "O servico nao deve ser executado acima da altitude de pouso.")
	assert_almost_eq(player.health_component.current_health, 500.0, 0.01, "Blindagem nao deve reparar com altitude excessiva.")


func test_ammo_crate_replenishes_twenty_five_percent() -> void:
	var ammo_crate: SupplyPickup = supply_scene.instantiate() as SupplyPickup
	ammo_crate.pickup_type = SupplyPickup.PickupType.AMMO_CRATE
	ammo_crate.ammo_fraction = 0.25
	add_child_autofree(ammo_crate)
	
	var player: PlayerHelicopter = player_scene.instantiate() as PlayerHelicopter
	add_child_autofree(player)
	
	# Reduz municao do slot primario pela metade (1200 -> 600)
	player.weapon_manager.ammo_counts[0] = 600
	
	watch_signals(ammo_crate)
	
	var collected: bool = ammo_crate.collect(player)
	assert_true(collected, "A caixa de municao deve ser coletada com sucesso.")
	
	# +25% de 1200 = +300 -> 600 + 300 = 900
	assert_eq(player.weapon_manager.ammo_counts[0], 900, "Municao deve aumentar em 25% da capacidade maxima.")


func test_fuel_drum_restores_thirty_fuel() -> void:
	var fuel_drum: SupplyPickup = supply_scene.instantiate() as SupplyPickup
	fuel_drum.pickup_type = SupplyPickup.PickupType.FUEL_DRUM
	fuel_drum.fuel_amount = 30.0
	add_child_autofree(fuel_drum)
	
	var player: PlayerHelicopter = player_scene.instantiate() as PlayerHelicopter
	add_child_autofree(player)
	player.fuel_component.current_fuel = 45.0
	
	watch_signals(fuel_drum)
	
	var collected: bool = fuel_drum.collect(player)
	assert_true(collected, "O tambor de combustivel deve ser coletado com sucesso.")
	
	assert_almost_eq(player.fuel_component.current_fuel, 75.0, 0.01, "Combustivel deve aumentar em exatamente +30.0 unidades.")
