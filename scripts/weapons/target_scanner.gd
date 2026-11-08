## Scanner tatico para deteccao e travamento de alvos hostis em cone frontal.
##
## Efetua varredura angular e por distancia para aquisicao do alvo mais proximo,
## alimentando o sistema de teleguiamento de mísseis Hellfire e a interface de combate.
class_name TargetScanner
extends Node

## Emitido quando um novo alvo hostil e adquirido dentro dos parametros de travamento.
signal target_locked(target: Node3D)

## Emitido quando o alvo travado sai da area de cobertura ou e destruido.
signal target_lost()

@export_group("Parametros de Varredura")
## Distancia maxima de alcance do sensor em metros.
@export var max_range: float = 60.0

## Abertura total do cone de travamento em graus.
@export var cone_angle_deg: float = 40.0

## Intervalo temporal entre ciclos de varredura automatica (segundos).
@export var scan_interval: float = 0.1

## Alvo atualmente rastreado pelo scanner.
var current_target: Node3D = null

var _scan_timer: float = 0.0


## Executa a busca pelo alvo mais proximo posicionado dentro do cone angular.
##
## Args:
##     origin (Vector3): Ponto de origem do sensor no espaco.
##     forward (Vector3): Vetor frontal de orientacao do sensor.
##     cone_deg (float): Abertura total do cone em graus.
##     range_dist (float): Alcance maximo em metros.
##     candidates (Array[Node3D]): Lista de entidades candidatas a alvo.
##
## Returns:
##     Node3D: Instancia do alvo selecionado ou null se nenhum satisfizer os criterios.
func find_best_target(origin: Vector3, forward: Vector3, cone_deg: float, range_dist: float, candidates: Array[Node3D]) -> Node3D:
	var forward_norm: Vector3 = forward.normalized()
	var half_cone_rad: float = deg_to_rad(cone_deg * 0.5)
	
	var best_candidate: Node3D = null
	var best_distance: float = range_dist + 1.0
	
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		
		var to_target: Vector3 = candidate.global_position - origin
		var distance: float = to_target.length()
		
		if distance > range_dist or distance < 0.05:
			continue
		
		var dir_to_target: Vector3 = to_target / distance
		var angle_rad: float = forward_norm.angle_to(dir_to_target)
		
		if angle_rad <= half_cone_rad:
			if distance < best_distance:
				best_distance = distance
				best_candidate = candidate
	
	return best_candidate


## Executa a varredura automatica utilizando entidades cadastradas no grupo 'enemies'.
##
## Args:
##     scanner_node (Node3D): No de referencia espacial para calculo de proa e posicao.
##     tree (SceneTree): Arvore de cena ativa para obtencao dos nos de inimigos.
##
## Returns:
##     Node3D: Alvo ativo apos o ciclo de varredura.
func scan_from_node(scanner_node: Node3D, tree: SceneTree) -> Node3D:
	if scanner_node == null or tree == null:
		return null
	
	var candidates: Array[Node3D] = []
	var enemy_nodes: Array[Node] = tree.get_nodes_in_group("enemies")
	for node in enemy_nodes:
		if node is Node3D and is_instance_valid(node):
			candidates.append(node as Node3D)
	
	var origin: Vector3 = scanner_node.global_position
	var forward: Vector3 = -scanner_node.global_transform.basis.z
	
	var found: Node3D = find_best_target(origin, forward, cone_angle_deg, max_range, candidates)
	_update_lock_state(found)
	return current_target


## Limpa manualmente o alvo ativo e emite os sinais correspondentes.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func clear_target() -> void:
	if current_target != null:
		current_target = null
		target_lost.emit()
		if EventBus != null:
			EventBus.target_lost.emit()


## Atualiza as transicoes de estado de travamento e notifica os canais de eventos.
##
## Args:
##     new_target (Node3D): Alvo identificado no ciclo mais recente.
##
## Returns:
##     void
func _update_lock_state(new_target: Node3D) -> void:
	if new_target != current_target:
		current_target = new_target
		if current_target != null:
			target_locked.emit(current_target)
			if EventBus != null:
				EventBus.target_locked.emit(current_target)
		else:
			target_lost.emit()
			if EventBus != null:
				EventBus.target_lost.emit()
