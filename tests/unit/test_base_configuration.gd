extends GutTest

## Testes unitarios para validacao da TASK-010 (Configuracao Base, InputMap, Audio e Autoloads).


func test_singletons_exist() -> void:
	assert_not_null(EventBus, "EventBus deve estar acessivel globalmente.")
	assert_not_null(GameState, "GameState deve estar acessivel globalmente.")
	assert_not_null(MetaProgression, "MetaProgression deve estar acessivel globalmente.")


func test_event_bus_signals() -> void:
	var expected_signals: Array[String] = [
		"player_health_changed",
		"player_fuel_changed",
		"player_fuel_depleted",
		"player_died",
		"weapon_selected",
		"weapon_ammo_changed",
		"target_locked",
		"target_lost",
		"civilian_boarded",
		"civilian_extracted",
		"civilian_killed",
		"rescue_zone_suppressed",
		"shelter_destroyed",
		"data_crate_opened",
		"boon_applied",
		"boss_phase_changed",
		"boss_defeated",
		"mission_accomplished",
		"mission_failed",
		"radio_transmission_requested"
	]
	for sig_name in expected_signals:
		assert_true(EventBus.has_signal(sig_name), "EventBus deve conter o sinal: " + sig_name)


func test_physics_collision_layers() -> void:
	var expected_layers: Dictionary = {
		"layer_names/3d_physics/layer_1": "World_Static",
		"layer_names/3d_physics/layer_2": "Player_Air",
		"layer_names/3d_physics/layer_3": "Enemies_Ground",
		"layer_names/3d_physics/layer_4": "Enemies_Air",
		"layer_names/3d_physics/layer_5": "Player_Projectiles",
		"layer_names/3d_physics/layer_6": "Enemy_Projectiles",
		"layer_names/3d_physics/layer_7": "Civilians",
		"layer_names/3d_physics/layer_8": "Zones_Trigger"
	}
	for key in expected_layers:
		var val: String = ProjectSettings.get_setting(key)
		assert_eq(val, expected_layers[key], "Camada de fisica 3D incorreta para " + key)


func test_input_map_actions() -> void:
	var required_actions: Array[String] = [
		"move_north",
		"move_south",
		"move_west",
		"move_east",
		"altitude_descend",
		"fire_primary",
		"weapon_slot_1",
		"weapon_slot_2",
		"weapon_slot_3",
		"weapon_cycle_next"
	]
	for action in required_actions:
		assert_true(InputMap.has_action(action), "InputMap deve conter a acao: " + action)


func test_audio_bus_layout() -> void:
	var layout_path: String = ProjectSettings.get_setting("audio/buses/default_bus_layout")
	assert_eq(layout_path, "res://default_bus_layout.tres", "Layout de audio padrao deve ser default_bus_layout.tres")
	assert_true(FileAccess.file_exists(layout_path), "Arquivo default_bus_layout.tres deve existir.")
	
	var layout: AudioBusLayout = load(layout_path)
	assert_not_null(layout, "Recurso AudioBusLayout deve ser carregado com sucesso.")


func test_game_state_lifecycle() -> void:
	GameState.start_new_run()
	assert_eq(GameState.current_status, GameState.RunStatus.IN_PROGRESS, "Run status deve ser IN_PROGRESS ao iniciar run.")
	assert_eq(GameState.rescued_in_current_run, 0, "Contagem de civis resgatados deve iniciar em zero.")
	
	GameState.register_extracted_civilians(2)
	assert_eq(GameState.rescued_in_current_run, 2, "Contagem de civis deve acumular extracoes.")
	
	GameState.complete_run_victory()
	assert_eq(GameState.current_status, GameState.RunStatus.VICTORY, "Run status deve ser VICTORY apos conclusao.")


func test_meta_progression_tokens_and_upgrades() -> void:
	var initial_tokens: int = MetaProgression.personnel_tokens
	MetaProgression.add_personnel_tokens(10)
	assert_eq(MetaProgression.personnel_tokens, initial_tokens + 10, "add_personnel_tokens deve incrementar saldo.")
	
	var lvl: int = MetaProgression.get_upgrade_level("expand_cabin")
	assert_true(lvl >= 0, "Nivel de upgrade expand_cabin deve ser maior ou igual a 0.")
