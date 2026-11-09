extends GutTest

## Testes unitarios para validacao da TASK-010 (Configuracao Base, InputMap, Audio e Autoloads).

const TEST_SAVE_PATH: String = "user://test_meta_progression.json"
var _original_save_path: String = ""
var _original_tokens: int = 0
var _original_upgrades: Dictionary[String, int] = {}


func before_all() -> void:
	_original_save_path = MetaProgression.save_path
	_original_tokens = MetaProgression.personnel_tokens
	_original_upgrades = MetaProgression.upgrade_levels.duplicate()
	MetaProgression.save_path = TEST_SAVE_PATH


func after_all() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	MetaProgression.save_path = _original_save_path
	MetaProgression.personnel_tokens = _original_tokens
	MetaProgression.upgrade_levels = _original_upgrades


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
	
	# Verificacao das rotas de bus acustico (TASK-092)
	var expected_buses: Dictionary = {
		"SFX_Player": "SFX",
		"SFX_Weapons": "SFX",
		"SFX_Combat": "SFX",
		"UI_Alarms": "UI",
		"UI_Chimes": "UI"
	}
	for bus_name in expected_buses:
		var bus_idx: int = AudioServer.get_bus_index(bus_name)
		assert_ne(bus_idx, -1, "Bus de audio %s deve existir no AudioServer." % bus_name)
		var send_name: String = AudioServer.get_bus_send(bus_idx)
		assert_eq(send_name, expected_buses[bus_name], "Bus %s deve enviar sinal para %s." % [bus_name, expected_buses[bus_name]])


func test_helicopter_spatial_audio_and_pitch_modulation() -> void:
	var helo_scene: PackedScene = load("res://scenes/entities/player/player_helicopter.tscn")
	assert_not_null(helo_scene, "A cena player_helicopter.tscn deve carregar sem erros.")
	
	var helo: PlayerHelicopter = helo_scene.instantiate() as PlayerHelicopter
	add_child_autofree(helo)
	
	# AudioStreamPlayer3D do rotor
	var rotor_audio: AudioStreamPlayer3D = helo.get_node_or_null("RotorAudioPlayer") as AudioStreamPlayer3D
	assert_not_null(rotor_audio, "PlayerHelicopter deve conter no RotorAudioPlayer do tipo AudioStreamPlayer3D.")
	assert_eq(rotor_audio.bus, &"SFX_Player", "RotorAudioPlayer deve estar direcionado ao bus SFX_Player.")
	assert_not_null(rotor_audio.stream, "RotorAudioPlayer deve possuir stream atribuido.")
	
	# Modulacao de pitch baseada na velocidade (0.95 em repouso a 1.15 na vel maxima)
	helo.velocity = Vector3.ZERO
	helo.update_rotor_audio_pitch(0.0)
	assert_almost_eq(rotor_audio.pitch_scale, 0.95, 0.01, "Pitch em repouso deve ser 0.95.")
	
	helo.update_rotor_audio_pitch(22.0)
	assert_almost_eq(rotor_audio.pitch_scale, 1.15, 0.01, "Pitch na velocidade maxima (22 m/s) deve ser 1.15.")
	
	# AudioStreamPlayer do alarme de combustivel
	var fuel_alarm: AudioStreamPlayer = helo.get_node_or_null("FuelAlarmAudioPlayer") as AudioStreamPlayer
	assert_not_null(fuel_alarm, "PlayerHelicopter deve conter FuelAlarmAudioPlayer.")
	assert_eq(fuel_alarm.bus, &"UI_Alarms", "FuelAlarmAudioPlayer deve estar direcionado ao bus UI_Alarms.")


func test_combat_and_impact_spatial_audio() -> void:
	var impact_scene: PackedScene = load("res://scenes/vfx/impact_effect.tscn")
	assert_not_null(impact_scene, "A cena impact_effect.tscn deve carregar sem erros.")
	
	var impact: ImpactEffect = impact_scene.instantiate() as ImpactEffect
	add_child_autofree(impact)
	
	var audio_player: AudioStreamPlayer3D = impact.get_node_or_null("ImpactAudio") as AudioStreamPlayer3D
	assert_not_null(audio_player, "ImpactEffect deve conter AudioStreamPlayer3D para atenuacao acustica espacial.")
	assert_eq(audio_player.bus, &"SFX_Combat", "ImpactAudio deve estar direcionado ao bus SFX_Combat.")
	assert_lte(audio_player.max_distance, 35.0, "Distancia maxima de corte acustico 3D deve ser <= 35m.")



func test_game_state_lifecycle() -> void:
	GameState.start_new_run()
	assert_eq(GameState.current_status, GameState.RunStatus.IN_PROGRESS, "Run status deve ser IN_PROGRESS ao iniciar run.")
	assert_eq(GameState.rescued_in_current_run, 0, "Contagem de civis resgatados deve iniciar em zero.")
	
	GameState.register_extracted_civilians(2)
	assert_eq(GameState.rescued_in_current_run, 2, "Contagem de civis deve acumular extracoes.")
	
	GameState.complete_run_victory()
	assert_eq(GameState.current_status, GameState.RunStatus.VICTORY, "Run status deve ser VICTORY apos conclusao.")


func test_meta_progression_tokens_and_upgrades() -> void:
	MetaProgression.reset_state()
	assert_eq(MetaProgression.personnel_tokens, 0, "reset_state deve zerar tokens.")
	
	MetaProgression.add_personnel_tokens(10)
	assert_eq(MetaProgression.personnel_tokens, 10, "add_personnel_tokens deve incrementar saldo para 10.")
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH), "Arquivo de teste deve ser criado no caminho isolado.")
	
	var lvl: int = MetaProgression.get_upgrade_level("expand_cabin")
	assert_eq(lvl, 0, "Nivel de upgrade expand_cabin inicial deve ser 0.")


const MainLoopCoordinatorScript = preload("res://scripts/core/main.gd")
const Mission01MidwayScript = preload("res://scenes/core/mission_01_midway.gd")


func test_main_loop_coordinator_lifecycle() -> void:
	var main_coordinator: Node3D = MainLoopCoordinatorScript.new()
	add_child_autofree(main_coordinator)
	
	assert_eq(main_coordinator.current_state, main_coordinator.ScreenState.HANGAR, "Main deve iniciar na tela de Hangar.")
	assert_not_null(main_coordinator.current_scene_instance, "Instancia do Hangar deve existir.")
	assert_true(main_coordinator.current_scene_instance is HangarScreen, "Tela inicial deve ser do tipo HangarScreen.")
	
	# Aciona o inicio de missao
	main_coordinator.start_mission()
	assert_eq(main_coordinator.current_state, main_coordinator.ScreenState.MISSION, "Main deve transicionar para estado MISSION.")
	assert_not_null(main_coordinator.current_scene_instance, "Instancia da missao deve existir.")
	assert_true(main_coordinator.current_scene_instance.get_script() == Mission01MidwayScript, "Tela deve ser do tipo Mission01Midway.")
	
	# Retorna para o Hangar
	main_coordinator.show_hangar()
	assert_eq(main_coordinator.current_state, main_coordinator.ScreenState.HANGAR, "Main deve retornar ao estado HANGAR.")
	assert_true(main_coordinator.current_scene_instance is HangarScreen, "Tela ativa deve ser HangarScreen.")
