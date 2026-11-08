## Gerenciador de fluxo principal e orquestrador de transicao de telas.
##
## Controla o ciclo de vida global do jogo, alternando entre a tela de Hangar
## (onde o jogador adquire melhorias com Personnel Tokens) e as fases de incursao.
class_name MainLoopCoordinator
extends Node3D

## Estados de navegacao do loop principal.
enum ScreenState {
	HANGAR,
	MISSION
}

## Referencia a cena do Hangar de meta-progressao.
@export var hangar_scene: PackedScene

## Referencia a cena da Missao 1 no Atol de Midway.
@export var mission_scene: PackedScene

## Estado de tela ativo no momento.
var current_state: ScreenState = ScreenState.HANGAR

## Instancia do nó de tela atualmente ativo como filho.
var current_scene_instance: Node = null


## Inicializa o orquestrador, carrega cenas padrao e exibe a tela de Hangar.
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
	_load_default_scenes()
	_connect_event_bus()
	show_hangar()


## Conecta aos sinais de conclusao ou falha de missao do EventBus global.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _connect_event_bus() -> void:
	if EventBus == null:
		return
	
	if not EventBus.mission_accomplished.is_connected(_on_mission_accomplished):
		EventBus.mission_accomplished.connect(_on_mission_accomplished)
	
	if not EventBus.mission_failed.is_connected(_on_mission_failed):
		EventBus.mission_failed.connect(_on_mission_failed)


## Remove a tela ativa atual e instancia a tela de Hangar e meta-progressao.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func show_hangar() -> void:
	_clear_current_scene()
	current_state = ScreenState.HANGAR
	
	if hangar_scene == null:
		return
	
	var hangar_instance: Node = hangar_scene.instantiate()
	current_scene_instance = hangar_instance
	add_child(hangar_instance)
	
	if hangar_instance.has_signal("mission_launch_requested"):
		hangar_instance.connect("mission_launch_requested", start_mission)


## Remove o Hangar e inicializa a incursao de combate na Missao 1.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func start_mission() -> void:
	_clear_current_scene()
	current_state = ScreenState.MISSION
	
	if mission_scene == null:
		return
	
	var mission_instance: Node = mission_scene.instantiate()
	current_scene_instance = mission_instance
	add_child(mission_instance)


## Callback acionado quando a missao e concluida com vitoria.
##
## Aguarda a conclusao dos dialogos finais e retorna para a tela de Hangar.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_mission_accomplished() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		await tree.create_timer(5.0).timeout
	show_hangar()


## Callback acionado quando a missao falha (destruicao ou pane seca).
##
## Aguarda a transmissao de encerramento e retorna para a tela de Hangar.
##
## Args:
##     _reason (String): Motivo do fracasso da incursao.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_mission_failed(_reason: String) -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		await tree.create_timer(4.0).timeout
	show_hangar()


## Libera a instancia de tela atualmente em exibicao.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _clear_current_scene() -> void:
	if current_scene_instance != null and is_instance_valid(current_scene_instance):
		current_scene_instance.queue_free()
		current_scene_instance = null


## Carrega as cenas de Hangar e Missao caso nao atribuidas no inspetor.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _load_default_scenes() -> void:
	if hangar_scene == null and ResourceLoader.exists("res://scenes/roguelite/hangar_screen.tscn"):
		hangar_scene = ResourceLoader.load("res://scenes/roguelite/hangar_screen.tscn")
	
	if mission_scene == null and ResourceLoader.exists("res://scenes/core/mission_01_midway.tscn"):
		mission_scene = ResourceLoader.load("res://scenes/core/mission_01_midway.tscn")
