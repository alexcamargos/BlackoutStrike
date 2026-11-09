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


func test_helipad_services_on_elevated_platform() -> void:
	var helipad: AllyBaseHelipad = helipad_scene.instantiate() as AllyBaseHelipad
	add_child_autofree(helipad)
	# Heliponto situado no topo de uma plataforma elevada a 6.0m
	helipad.global_position = Vector3(50.0, 6.0, 50.0)
	
	var player: PlayerHelicopter = player_scene.instantiate() as PlayerHelicopter
	add_child_autofree(player)
	# Helicóptero pousado a 6.8m (0.8m acima da plataforma do heliponto)
	player.global_position = Vector3(50.0, 6.8, 50.0)
	player.health_component.current_health = 700.0
	player.fuel_component.current_fuel = 40.0
	
	helipad._on_body_entered(player)
	helipad.step(1.0)
	
	assert_true(helipad.is_servicing, "O heliponto deve atender aeronave em plataforma elevada usando cota relativa.")
	assert_almost_eq(player.health_component.current_health, 740.0, 0.1, "Blindagem deve regenerar normalmente em heliponto elevado.")
	assert_almost_eq(player.fuel_component.current_fuel, 55.0, 0.1, "Combustivel deve ser bombeado normalmente em heliponto elevado.")



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


func test_supply_pickup_reactive_type_styling() -> void:
	var pickup: SupplyPickup = supply_scene.instantiate() as SupplyPickup
	add_child_autofree(pickup)
	
	# Inicialmente Ammo Crate (verde)
	var mat_ammo: StandardMaterial3D = pickup.mesh_instance.material_override as StandardMaterial3D
	assert_not_null(mat_ammo, "Material deve estar configurado.")
	assert_almost_eq(mat_ammo.albedo_color.g, 0.45, 0.05, "Cor albedo inicial deve ser verde.")
	
	# Altera dinamicamente para Fuel Drum (dourado/amarelo)
	pickup.pickup_type = SupplyPickup.PickupType.FUEL_DRUM
	var mat_fuel: StandardMaterial3D = pickup.mesh_instance.material_override as StandardMaterial3D
	assert_almost_eq(mat_fuel.albedo_color.r, 0.85, 0.05, "Cor albedo atualizada deve ser amarela.")


func test_fuel_depot_refuels_up_to_cap_and_does_not_repair_or_unload() -> void:
	var depot_scene: PackedScene = preload("res://scenes/environment/fuel_depot.tscn")
	var depot: FuelDepot = depot_scene.instantiate() as FuelDepot
	add_child_autofree(depot)
	depot.global_position = Vector3(0.0, 0.0, 0.0)
	
	var player: PlayerHelicopter = player_scene.instantiate() as PlayerHelicopter
	add_child_autofree(player)
	player.global_position = Vector3(0.0, 0.8, 0.0) # Pousado no FOB
	
	player.health_component.current_health = 700.0
	player.fuel_component.current_fuel = 30.0
	player.cargo_component.current_occupants = 3
	
	depot._on_body_entered(player)
	
	# Simula 2.0 segundos de abastecimento (2s * 12 u/s = +24 -> 54.0)
	depot.step(2.0)
	assert_almost_eq(player.fuel_component.current_fuel, 54.0, 0.01, "FOB deve abastecer na taxa de 12 u/s.")
	assert_eq(player.health_component.current_health, 700.0, "FOB nao pode consertar a aeronave.")
	assert_eq(player.cargo_component.current_occupants, 3, "FOB nao pode desembarcar passageiros.")
	
	# Simula mais 5.0 segundos: 54 + 60 = 114 -> mas o teto eh 75.0
	depot.step(5.0)
	assert_almost_eq(player.fuel_component.current_fuel, 75.0, 0.01, "FOB deve limitar o reabastecimento a 75 unidades.")
	assert_false(depot.is_refueling, "Ao atingir o teto de 75 unidades, is_refueling deve ser falso.")

