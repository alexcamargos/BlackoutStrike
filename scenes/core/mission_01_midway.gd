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
	if GameState != null:
		GameState.start_new_run()
	
	if spawn_director != null and player_helicopter != null:
		spawn_director.player_ref = player_helicopter
	
	_connect_event_bus_signals()
	
	# Transmissao inicial de radio militar
	if EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"vasquez",
			"OVERWATCH VANGUARD (DRA. VASQUEZ)",
			"Infiltracao iniciada no Atol de Midway. Resgate os especialistas e neutralize o Apex Bastion.",
			5.0
		)
	
	mission_ready.emit()


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
	if EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"vance",
			"COM. VANCE",
			"%s afundado! Ameaca costeira neutralizada. Missao cumprida, Mohawk III!" % boss_name,
			5.0
		)


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
