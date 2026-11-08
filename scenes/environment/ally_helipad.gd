## Area do Heliponto da Base Aliada responsavel por reparo, reabastecimento e desembarque.
##
## Monitora o pouso da aeronave (Y <= 1.2m), descarrega passageiros incrementando os
## tokens de meta-progressao permanente e realiza manutencao continua de HP e combustivel.
class_name AllyBaseHelipad
extends Area3D

## Sinal emitido quando passageiros sao desembarcados com sucesso na base.
signal civilians_unloaded_at_base(count: int, total_tokens: int)

## Cota maxima de altitude para considerar a aeronave pousada/atracada.
@export var max_service_altitude: float = 1.2

## Velocidade horizontal maxima admitida para manter o servico ativo.
@export var max_service_speed: float = 4.0

## Taxa de regeneracao de blindagem em HP por segundo.
@export var repair_rate: float = 40.0

## Taxa de bombeamento de combustivel em unidades por segundo.
@export var refuel_rate: float = 15.0

## Referencia a aeronave do jogador atualmente na area de pouso.
var player_helicopter: Node3D = null

## Flag indicativa se a aeronave esta em condicoes estaveis de atendimento.
var is_servicing: bool = false


## Inicializa as mascaras de colisao da Camada 8 (Zones_Trigger) e conexoes de monitoramento.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	collision_layer = 128 # Camada 8 = Zones_Trigger
	collision_mask = 2    # Camada 2 = Player_Air
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Executa o ciclo de fisica verificando e abastecendo a aeronave.
##
## Args:
##     delta (float): Intervalo de tempo do quadro de fisica em segundos.
##
## Returns:
##     void
func _physics_process(delta: float) -> void:
	step(delta)


## Executa uma etapa de servico no heliponto (suporta simulacao direta em testes).
##
## Args:
##     delta (float): Intervalo de tempo da etapa em segundos.
##
## Returns:
##     void
func step(delta: float) -> void:
	if not is_instance_valid(player_helicopter):
		is_servicing = false
		return
	
	var current_altitude: float = player_helicopter.global_position.y
	var horizontal_speed: float = 0.0
	
	if player_helicopter is CharacterBody3D:
		var cb: CharacterBody3D = player_helicopter as CharacterBody3D
		horizontal_speed = Vector2(cb.velocity.x, cb.velocity.z).length()
	
	var relative_altitude: float = current_altitude - global_position.y
	var can_service: bool = relative_altitude <= max_service_altitude and relative_altitude >= -0.2 and horizontal_speed <= max_service_speed
	if not can_service:
		is_servicing = false
		return
	
	is_servicing = true
	
	# Desembarque imediato de passageiros
	_process_passenger_unloading()
	
	# Manutencao de blindagem e combustivel
	_process_maintenance(delta)


## Descarrega passageiros acumulados no CargoComponent e atualiza meta-progressao.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _process_passenger_unloading() -> void:
	var cargo: CargoComponent = _find_cargo_component(player_helicopter)
	if cargo != null and cargo.current_occupants > 0:
		var count: int = cargo.unload_all()
		if count > 0:
			if MetaProgression != null:
				MetaProgression.add_personnel_tokens(count)
			if GameState != null:
				GameState.register_extracted_civilians(count)
			elif EventBus != null:
				EventBus.civilian_extracted.emit(count)
			
			var current_tokens: int = MetaProgression.personnel_tokens if MetaProgression != null else count
			civilians_unloaded_at_base.emit(count, current_tokens)


## Aplica taxas continuas de reparo de blindagem e reabastecimento de combustivel.
##
## Args:
##     delta (float): Intervalo de tempo em segundos.
##
## Returns:
##     void
func _process_maintenance(delta: float) -> void:
	var health_comp: HealthComponent = _find_health_component(player_helicopter)
	if health_comp != null and not health_comp.is_destroyed():
		health_comp.repair(repair_rate * delta)
	
	var fuel_comp: FuelComponent = _find_fuel_component(player_helicopter)
	if fuel_comp != null and not fuel_comp.is_empty():
		fuel_comp.refuel(refuel_rate * delta)


## Localiza o CargoComponent na hierarquia da aeronave.
##
## Args:
##     node (Node): Instancia a ser inspecionada.
##
## Returns:
##     CargoComponent: Instancia encontrada ou null.
func _find_cargo_component(node: Node) -> CargoComponent:
	if node is CargoComponent:
		return node as CargoComponent
	return node.get_node_or_null("CargoComponent") as CargoComponent


## Localiza o HealthComponent na hierarquia da aeronave.
##
## Args:
##     node (Node): Instancia a ser inspecionada.
##
## Returns:
##     HealthComponent: Instancia encontrada ou null.
func _find_health_component(node: Node) -> HealthComponent:
	if node is HealthComponent:
		return node as HealthComponent
	return node.get_node_or_null("HealthComponent") as HealthComponent


## Localiza o FuelComponent na hierarquia da aeronave.
##
## Args:
##     node (Node): Instancia a ser inspecionada.
##
## Returns:
##     FuelComponent: Instancia encontrada ou null.
func _find_fuel_component(node: Node) -> FuelComponent:
	if node is FuelComponent:
		return node as FuelComponent
	return node.get_node_or_null("FuelComponent") as FuelComponent


## Manipulador disparado ao detectar a entrada de corpo na area do heliponto.
##
## Args:
##     body (Node3D): Corpo colidido.
##
## Returns:
##     void
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "PlayerHelicopter" or body is PlayerHelicopter:
		player_helicopter = body


## Manipulador disparado ao detectar a saida de corpo da area do heliponto.
##
## Args:
##     body (Node3D): Corpo que deixou a area.
##
## Returns:
##     void
func _on_body_exited(body: Node3D) -> void:
	if body == player_helicopter:
		player_helicopter = null
		is_servicing = false
