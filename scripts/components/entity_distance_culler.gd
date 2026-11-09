## Componente de culling dinamico por distancia para manutencao de performance (60+ FPS).
##
## Desativa o processamento de fisica e visibilidade de entidades distantes a mais de 250m do jogador,
## reativando o ciclo operacional quando o helicóptero se aproxima da area.
class_name EntityDistanceCuller
extends Node

## Distancia maxima em metros para manter a entidade ativa.
@export var culling_distance: float = 250.0

## Intervalo em segundos entre verificacoes de distancia (evita sobrecarga de CPU por quadro).
@export var check_interval: float = 0.25

## Referencia explicita ao nó alvo a ser culled (padrao: nó pai).
@export var target_node: Node3D = null

## Acumulador de tempo decorrido.
var _time_accumulator: float = 0.0

## Referencia em cache ao no do jogador.
var _player_ref: Node3D = null

## Flag indicando se a entidade esta atualmente culled (inativa).
var is_culled: bool = false


## Inicializa o componente e estabelece o alvo padrão se nao atribuido.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	if target_node == null and get_parent() is Node3D:
		target_node = get_parent() as Node3D


## Processa a verificacao periodica de proximidade.
##
## Args:
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func _process(delta: float) -> void:
	_time_accumulator += delta
	if _time_accumulator >= check_interval:
		_time_accumulator = 0.0
		update_culling_state()


## Executa uma atualizacao de culling com base na distancia para o jogador.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func update_culling_state() -> void:
	if target_node == null:
		return
	
	if _player_ref == null or not is_instance_valid(_player_ref):
		_find_player()
	
	if _player_ref == null:
		return
	
	var dist_sq: float = target_node.global_position.distance_squared_to(_player_ref.global_position)
	var max_dist_sq: float = culling_distance * culling_distance
	
	if dist_sq > max_dist_sq:
		if not is_culled:
			is_culled = true
			target_node.process_mode = Node.PROCESS_MODE_DISABLED
			target_node.visible = false
	else:
		if is_culled:
			is_culled = false
			target_node.process_mode = Node.PROCESS_MODE_INHERIT
			target_node.visible = true


## Busca o nó do jogador na árvore de cena caso nao esteja em cache.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _find_player() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var players: Array[Node] = tree.get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node3D:
		_player_ref = players[0] as Node3D
