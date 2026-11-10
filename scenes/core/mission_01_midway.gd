## Orquestrador de missao e eventos de combate para o Atol de Midway.
##
## Gerencia o ciclo de vida da Missao 1, conectando o SpawnDirector, telemetria
## do helicóptero, transmicoes de radio militar e condicoes de vitoria e derrota.
class_name Mission01Midway
extends Node3D

## Sinal emitido quando a inicializacao da missao estiver concluida.
signal mission_ready()

## Referencias aos nós principais da missao.
@onready var spawn_director: SpawnDirector = $SpawnDirector
@onready var player_helicopter: PlayerHelicopter = $ActiveEntities/PlayerHelicopter
@onready var boss: BossApexBastion = get_node_or_null("ActiveEntities/Enemies/BossApexBastion") as BossApexBastion

var _verification_frame_count: int = 0
var _is_verification_capture: bool = false


## Inicializa a incursao, vincula referencias taticas e transmite ordens de combate.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _ready() -> void:
	for arg: String in OS.get_cmdline_args():
		if arg == "--capture-verification":
			_is_verification_capture = true
			break
	if GameState != null:
		GameState.start_new_run()
	
	if spawn_director != null and player_helicopter != null:
		spawn_director.player_ref = player_helicopter
	
	_connect_event_bus_signals()
	
	# Transmissao inicial de radio militar na decolagem do USS Vanguard
	if EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"vasquez",
			"OVERWATCH VANGUARD (DRA. VASQUEZ)",
			"Mohawk-1 liberado para decolagem! Siga a Noroeste [W + A] pelo canal de boias luminosas ate o Atol de Midway. Nao se afaste para o mar!",
			6.0
		)
	
	mission_ready.emit()


func _process(_delta: float) -> void:
	if _is_verification_capture:
		_verification_frame_count += 1
		if _verification_frame_count == 14:
			if EventBus != null:
				EventBus.player_health_changed.emit(750.0, 1000.0)
				EventBus.player_fuel_changed.emit(72.0, 100.0)
				EventBus.weapon_selected.emit(2, "Mísseis AGM-114 Hellfire")
				EventBus.weapon_ammo_changed.emit(2, 6, 6)
				EventBus.civilian_boarded.emit(3, 5)
				var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
				if enemies.size() > 0:
					EventBus.target_locked.emit(enemies[0] as Node3D)
		elif _verification_frame_count >= 28:
			var img: Image = get_viewport().get_texture().get_image()
			if img != null:
				img.save_png("res://scratch/current_gameplay.png")
				img.save_png("res://scratch/new_hud_verification.png")
				print("Visual Verification Capture salvo com sucesso.")
			get_tree().quit(0)


## Conecta aos sinais globais do EventBus para emitir radio chatter reativo.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _connect_event_bus_signals() -> void:
	if EventBus == null:
		return
	
	if not EventBus.shelter_destroyed.is_connected(_on_shelter_destroyed):
		EventBus.shelter_destroyed.connect(_on_shelter_destroyed)
	
	if not EventBus.civilian_extracted.is_connected(_on_civilian_extracted):
		EventBus.civilian_extracted.connect(_on_civilian_extracted)
	
	if not EventBus.boss_phase_changed.is_connected(_on_boss_phase_changed):
		EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	
	if not EventBus.boss_defeated.is_connected(_on_boss_defeated):
		EventBus.boss_defeated.connect(_on_boss_defeated)
	
	if not EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.connect(_on_player_died)


## Callback acionado na destruicao de um abrigo blindado.
##
## Args:
##     _pos (Vector3): Coordenadas do colapso.
##     _count (int): Quantidade de civis liberados no solo.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_shelter_destroyed(_pos: Vector3, _count: int) -> void:
	if EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"ruiz",
			"ENG. CHEFE RUIZ",
			"Estrutura do abrigo colapsou! Civis expostos no solo, cuidado com o fogo cruzado!",
			4.0
		)


## Callback acionado quando civis sao desembarcados no heliponto da base.
##
## Args:
##     total_rescued (int): Total acumulado de especialistas resgatados.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_civilian_extracted(total_rescued: int) -> void:
	if EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"vance",
			"COM. VANCE",
			"Especialistas resgatados com sucesso (%d). Fichas de pessoal creditadas." % total_rescued,
			3.5
		)


## Callback acionado na transicao de fases do chefe Apex Bastion.
##
## Args:
##     boss_name (String): Identificador do chefe.
##     phase_index (int): Indice da nova fase de combate.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_boss_phase_changed(boss_name: String, phase_index: int) -> void:
	if phase_index == 2 and EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"apex_net",
			"APEXNET",
			"Alerta: Blindagem do reator comprometida. Ativando baterias CIWS e salvas de misseis.",
			4.5
		)


## Callback acionado na vitoria sobre o chefe.
##
## Args:
##     boss_name (String): Identificador do chefe derrotado.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_boss_defeated(boss_name: String) -> void:
	if player_helicopter != null and player_helicopter.cargo_component != null:
		var remaining_civilians: int = player_helicopter.cargo_component.unload_all()
		if remaining_civilians > 0:
			if MetaProgression != null:
				MetaProgression.add_personnel_tokens(remaining_civilians)
			if GameState != null:
				GameState.register_extracted_civilians(remaining_civilians)
			elif EventBus != null:
				EventBus.civilian_extracted.emit(remaining_civilians)
	
	if EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"vance",
			"COM. VANCE",
			"%s afundado! Ameaca costeira neutralizada. Missao cumprida, Mohawk III!" % boss_name,
			5.0
		)
	
	if GameState != null:
		GameState.complete_run_victory()


## Callback acionado na queda da aeronave do jogador.
##
## Args:
##     cause (String): Motivo da perda da aeronave.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_player_died(cause: String) -> void:
	if EventBus != null:
		var message: String = "Sinal do Mohawk III perdido! Abortar incursao."
		if cause == "fuel_exhaustion":
			message = "Pane seca confirmada. Mohawk III colidiu no oceano. Missao abortada."
		EventBus.radio_transmission_requested.emit("vance", "COM. VANCE", message, 4.5)
	
	if GameState != null:
		GameState.fail_run(cause)
	elif EventBus != null:
		EventBus.mission_failed.emit(cause)
