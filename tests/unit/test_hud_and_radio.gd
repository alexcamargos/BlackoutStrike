## Testes unitarios para a interface HUD e Caixa de Transmissao de Radio militar.
extends GutTest

var hud: HUD
var radio_box: RadioTransmissionBox


func before_each() -> void:
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	hud = hud_scene.instantiate() as HUD
	add_child_autofree(hud)
	
	var radio_scene: PackedScene = load("res://scenes/ui/radio_transmission_box.tscn")
	radio_box = radio_scene.instantiate() as RadioTransmissionBox
	add_child_autofree(radio_box)


func test_hud_updates_health_bar() -> void:
	EventBus.player_health_changed.emit(850.0, 1000.0)
	assert_almost_eq(hud.health_bar.value, 850.0, 0.01, "A barra de vida deve refletir o valor de 850.")
	assert_almost_eq(hud.health_bar.max_value, 1000.0, 0.01, "O teto da barra de vida deve ser 1000.")


func test_hud_updates_fuel_bar() -> void:
	EventBus.player_fuel_changed.emit(42.5, 100.0)
	assert_almost_eq(hud.fuel_bar.value, 42.5, 0.01, "A barra de combustivel deve refletir o valor de 42.5.")
	assert_almost_eq(hud.fuel_bar.max_value, 100.0, 0.01, "O teto da barra de combustivel deve ser 100.")


func test_hud_updates_weapon_slots_and_selection() -> void:
	EventBus.weapon_selected.emit(1, "Foguetes Hydra 70")
	assert_eq(hud.active_slot_index, 1, "O slot ativo deve ser atualizado para o indice 1.")
	
	EventBus.weapon_ammo_changed.emit(1, 26, 32)
	assert_true(hud.ammo_labels[1].text.contains("26"), "O rotulo do slot 1 deve exibir a contagem de 26 municoes.")


func test_hud_cabin_full_alert_toggle() -> void:
	assert_false(hud.cabin_full_alert.visible, "O alerta CABIN FULL deve iniciar invisivel.")
	
	# Cabine cheia (5 de 5)
	EventBus.civilian_boarded.emit(5, 5)
	assert_true(hud.cabin_full_alert.visible, "O alerta CABIN FULL deve ficar visivel com lotacao esgotada.")
	assert_true(hud.cargo_label.text.contains("5 / 5"), "O tacometro de passageiros deve exibir '5 / 5'.")
	
	# Desembarque parcial
	EventBus.civilian_boarded.emit(2, 5)
	assert_false(hud.cabin_full_alert.visible, "O alerta CABIN FULL deve ocultar-se quando houver vagas na cabine.")
	assert_true(hud.cargo_label.text.contains("2 / 5"), "O tacometro deve atualizar para '2 / 5'.")


func test_hud_dynamic_cargo_capacity_on_extraction() -> void:
	EventBus.civilian_boarded.emit(4, 8)
	assert_true(hud.cargo_label.text.contains("4 / 8"), "O tacometro deve refletir a capacidade expandida de 8.")
	
	EventBus.civilian_extracted.emit(4)
	assert_true(hud.cargo_label.text.contains("0 / 8"), "Apos a extracao, o tacometro deve manter o teto dinamico de 8.")


func test_hud_target_lock_indicator() -> void:
	assert_false(hud.lock_indicator.visible, "O indicador de travamento de alvo deve iniciar invisivel.")
	
	var dummy_enemy: Node3D = Node3D.new()
	add_child_autofree(dummy_enemy)
	
	EventBus.target_locked.emit(dummy_enemy)
	assert_true(hud.lock_indicator.visible, "O indicador deve ficar visivel apos travamento confirmado.")
	
	EventBus.target_lost.emit()
	assert_false(hud.lock_indicator.visible, "O indicador deve ocultar-se quando o alvo for perdido.")


func test_radio_transmission_box_displays_message_and_auto_hides() -> void:
	assert_false(radio_box.visible, "A caixa de transmissao deve iniciar oculta.")
	
	EventBus.radio_transmission_requested.emit("vance", "COM. VANCE", "Infiltracao iniciada no Atol de Midway.", 1.5)
	
	assert_true(radio_box.visible, "A caixa de transmissao deve tornar-se visivel.")
	assert_eq(radio_box.callsign_label.text, "COM. VANCE", "O indicativo de chamada deve coincidir com o emissor.")
	assert_eq(radio_box.message_label.text, "Infiltracao iniciada no Atol de Midway.", "O texto da mensagem deve ser exibido com precisao.")
	
	# Simula decorrencia de tempo superior a duracao (1.5s)
	radio_box._process(1.6)
	assert_false(radio_box.visible, "A caixa de radio deve auto-ocultar-se apos esgotar a duracao.")


func test_hud_military_styling_and_segmented_bars() -> void:
	# Verificacao dos materiais de barras segmentadas
	assert_not_null(hud.health_bar.material, "HealthBar deve possuir um ShaderMaterial para visual segmentado militar.")
	var health_mat: ShaderMaterial = hud.health_bar.material as ShaderMaterial
	assert_not_null(health_mat, "Material da barra de vida deve ser ShaderMaterial.")
	
	assert_not_null(hud.fuel_bar.material, "FuelBar deve possuir um ShaderMaterial para visual segmentado militar.")
	var fuel_mat: ShaderMaterial = hud.fuel_bar.material as ShaderMaterial
	assert_not_null(fuel_mat, "Material da barra de combustivel deve ser ShaderMaterial.")
	
	# Atualizacao do fill_ratio no shader ao alterar vida
	EventBus.player_health_changed.emit(500.0, 1000.0)
	var health_ratio: float = health_mat.get_shader_parameter("fill_ratio")
	assert_almost_eq(health_ratio, 0.5, 0.01, "fill_ratio do shader de vida deve refletir 50%.")
	
	# Atualizacao do fill_ratio no shader ao alterar combustivel
	EventBus.player_fuel_changed.emit(25.0, 100.0)
	var fuel_ratio: float = fuel_mat.get_shader_parameter("fill_ratio")
	assert_almost_eq(fuel_ratio, 0.25, 0.01, "fill_ratio do shader de combustivel deve refletir 25%.")
	
	# Indicadores segmentados de passageiros (pips)
	assert_not_null(hud.passenger_pips_container, "HUD deve conter passenger_pips_container para exibicao diegetica.")
	EventBus.civilian_boarded.emit(3, 5)
	assert_eq(hud.passenger_pips_container.get_child_count(), 5, "Devem existir 5 pips de passageiros para capacidade 5.")
	var active_pips: int = 0
	for pip: Control in hud.passenger_pips_container.get_children():
		if pip.modulate.a > 0.5:
			active_pips += 1
	assert_eq(active_pips, 3, "3 pips devem estar acesos/ativos para 3 passageiros embarcados.")
	
	# Reticula de mira com feedback de travamento
	assert_not_null(hud.reticle_rect, "HUD deve possuir reticle_rect para feedback de mira militar.")
	var reticle_mat: ShaderMaterial = hud.reticle_rect.material as ShaderMaterial
	assert_not_null(reticle_mat, "reticle_rect deve possuir ShaderMaterial.")
	var dummy_enemy: Node3D = Node3D.new()
	add_child_autofree(dummy_enemy)
	EventBus.target_locked.emit(dummy_enemy)
	var is_locked_val: bool = reticle_mat.get_shader_parameter("is_locked")
	assert_true(is_locked_val, "is_locked no shader de reticula deve ser true apos travamento.")
	EventBus.target_lost.emit()
	var is_unlocked_val: bool = reticle_mat.get_shader_parameter("is_locked")
	assert_false(is_unlocked_val, "is_locked no shader deve retornar a false apos perda de alvo.")


func test_radio_transmission_box_portrait_and_scanlines() -> void:
	assert_not_null(radio_box.portrait_rect, "RadioTransmissionBox deve conter portrait_rect.")
	assert_not_null(radio_box.scanlines_overlay, "RadioTransmissionBox deve conter scanlines_overlay.")
	assert_not_null(radio_box.scanlines_overlay.material, "scanlines_overlay deve possuir ShaderMaterial.")
	
	# Transmissao de Nathan Cross
	EventBus.radio_transmission_requested.emit("cross", "GHOST-1 / NATHAN CROSS", "Incursao iniciada.", 3.0)
	assert_true(radio_box.visible, "Caixa deve estar visivel.")
	assert_not_null(radio_box.portrait_rect.texture, "Retrato de Nathan Cross deve estar atribuido.")
	assert_true(radio_box.portrait_rect.texture.resource_name.contains("cross"), "Textura deve ser de Nathan Cross.")
	
	# Transmissao de Julian Vane
	EventBus.radio_transmission_requested.emit("vane", "JULIAN VANE", "A ApexNet antecipou seus passos.", 3.0)
	assert_not_null(radio_box.portrait_rect.texture, "Retrato de Julian Vane deve estar atribuido.")
	assert_true(radio_box.portrait_rect.texture.resource_name.contains("vane"), "Textura deve ser de Julian Vane.")
	
	# Transmissao de Commander Vance
	EventBus.radio_transmission_requested.emit("vance", "COM. VANCE", "Extraiam os alvos imediatamente.", 3.0)
	assert_not_null(radio_box.portrait_rect.texture, "Retrato de Commander Vance deve estar atribuido.")
	assert_true(radio_box.portrait_rect.texture.resource_name.contains("vance"), "Textura deve ser de Commander Vance.")
	
	# Transmissao canonica de Dra. Elena Vasquez (Overwatch Vanguard)
	EventBus.radio_transmission_requested.emit("vasquez", "OVERWATCH VANGUARD (DRA. VASQUEZ)", "Perimetro seguro.", 3.0)
	assert_not_null(radio_box.portrait_rect.texture, "Retrato da Dra. Elena Vasquez deve estar atribuido.")
	assert_true(radio_box.portrait_rect.texture.resource_name.contains("vasquez"), "Textura deve ser da Dra. Elena Vasquez.")


func test_hud_deferred_telemetry_synchronization() -> void:
	var helo_scene: PackedScene = load("res://scenes/entities/player/player_helicopter.tscn")
	var helo: PlayerHelicopter = helo_scene.instantiate() as PlayerHelicopter
	add_child_autofree(helo)
	
	# Simula meta-progressao aplicando valores customizados
	helo.health_component.max_health = 1250.0
	helo.health_component.current_health = 1250.0
	helo.cargo_component.max_capacity = 8
	
	# Invoca a sincronizacao de telemetria
	helo.publish_telemetry()
	
	assert_almost_eq(hud.health_bar.max_value, 1250.0, 0.01, "HUD deve sincronizar a capacidade expandida de blindagem.")
	assert_true(hud.cargo_label.text.contains("8"), "HUD deve sincronizar o teto de passageiros para 8.")



const Mission01MidwayScript = preload("res://scenes/core/mission_01_midway.gd")


func test_mission_01_midway_ui_hierarchy_and_orchestrator() -> void:
	var mission_scene: PackedScene = load("res://scenes/core/mission_01_midway.tscn")
	assert_not_null(mission_scene, "A cena mission_01_midway.tscn deve existir e carregar sem erros.")
	
	var mission_node: Node = mission_scene.instantiate()
	add_child_autofree(mission_node)
	
	assert_true(mission_node.get_script() == Mission01MidwayScript, "O no raiz de Midway deve possuir o script Mission01Midway.")
	
	var radio_box_instance: Node = mission_node.get_node_or_null("CanvasLayer_UI/RadioTransmissionBox")
	assert_not_null(radio_box_instance, "CanvasLayer_UI deve conter a instancia da RadioTransmissionBox.")
	assert_true(radio_box_instance is RadioTransmissionBox, "A instancia deve ser do tipo RadioTransmissionBox.")
	
	var director_instance: SpawnDirector = mission_node.get_node_or_null("SpawnDirector") as SpawnDirector
	assert_not_null(director_instance, "SpawnDirector deve existir na cena da missao.")
	assert_true(director_instance.auto_spawn_on_ready, "SpawnDirector deve estar com auto_spawn_on_ready = true na missao.")


func test_mission_01_victory_and_failure_lifecycle() -> void:
	var mission_scene: PackedScene = load("res://scenes/core/mission_01_midway.tscn")
	assert_not_null(mission_scene, "A cena mission_01_midway.tscn deve existir.")
	var mission_node: Node = mission_scene.instantiate()
	add_child_autofree(mission_node)
	
	watch_signals(EventBus)
	
	# Testa ciclo de derrota ao cair a aeronave
	GameState.start_new_run()
	assert_eq(GameState.current_status, GameState.RunStatus.IN_PROGRESS, "Status deve iniciar em IN_PROGRESS.")
	
	mission_node._on_player_died("fuel_exhaustion")
	assert_eq(GameState.current_status, GameState.RunStatus.FAILED, "Status do GameState deve mudar para FAILED.")
	assert_signal_emitted(EventBus, "mission_failed", "EventBus.mission_failed deve ser emitido.")
	
	# Testa ciclo de vitoria ao derrotar o chefe Apex Bastion
	GameState.start_new_run()
	var player_helo = mission_node.get_node_or_null("ActiveEntities/PlayerHelicopter")
	if player_helo != null and player_helo.cargo_component != null:
		player_helo.cargo_component.current_occupants = 3
	
	var initial_tokens: int = MetaProgression.personnel_tokens
	mission_node._on_boss_defeated("Apex Bastion")
	
	assert_eq(GameState.current_status, GameState.RunStatus.VICTORY, "Status do GameState deve mudar para VICTORY.")
	assert_signal_emitted(EventBus, "mission_accomplished", "EventBus.mission_accomplished deve ser emitido.")
	if player_helo != null and player_helo.cargo_component != null:
		assert_eq(player_helo.cargo_component.current_occupants, 0, "Passageiros devem ser desembarcados na vitoria.")
		assert_eq(MetaProgression.personnel_tokens, initial_tokens + 3, "Tokens de pessoal devem ser creditados pelos sobreviventes evacuados.")

