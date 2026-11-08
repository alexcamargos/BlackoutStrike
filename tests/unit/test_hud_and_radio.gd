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
