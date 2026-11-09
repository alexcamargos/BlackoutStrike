## Posto Avancado Terrestre de Combustivel (FOB - Forward Operating Base).
##
## Heliponto secundario no Atol Central que permite pouso para reabastecimento de emergencia.
## Restrito estritamente a um teto parcial de 75 unidades de combustivel, sem reparo e sem desembarque.
class_name FuelDepot
extends Area3D

## Sinal emitido durante o reabastecimento ativo no posto avancado.
signal refuel_progress(current_fuel: float, max_cap: float)

## Cota maxima de altitude relativa para considerar a aeronave pousada.
@export var max_service_altitude: float = 1.2

## Velocidade horizontal maxima admitida para manter o servico ativo.
@export var max_service_speed: float = 4.0

## Taxa de reabastecimento em unidades por segundo.
@export var refuel_rate: float = 12.0

## Teto maximo de combustivel fornecido por este posto avancado (50% da capacidade total).
@export var max_refuel_cap: float = 75.0

## Referencia a aeronave do jogador atualmente na area do posto.
var player_helicopter: Node3D = null

## Flag indicativa se a operacao de abastecimento esta ativa.
var is_refueling: bool = false


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


## Executa uma etapa de servico de reabastecimento no posto (suporta simulacao direta em testes).
##
## Args:
##     delta (float): Intervalo de tempo da etapa em segundos.
##
## Returns:
##     void
func step(delta: float) -> void:
	if not is_instance_valid(player_helicopter):
		is_refueling = false
		return
	
	var current_altitude: float = player_helicopter.global_position.y
	var horizontal_speed: float = 0.0
	
	if player_helicopter is CharacterBody3D:
		var cb: CharacterBody3D = player_helicopter as CharacterBody3D
		horizontal_speed = Vector2(cb.velocity.x, cb.velocity.z).length()
	
	var relative_altitude: float = current_altitude - global_position.y
	var can_service: bool = (
		relative_altitude <= max_service_altitude
		and relative_altitude >= -0.2
		and horizontal_speed <= max_service_speed
	)
	
	if not can_service:
		is_refueling = false
		return
	
	var fuel: FuelComponent = _find_fuel_component(player_helicopter)
	if fuel != null and fuel.current_fuel < max_refuel_cap:
		fuel.refuel_capped(refuel_rate * delta, max_refuel_cap)
		is_refueling = fuel.current_fuel < max_refuel_cap
		refuel_progress.emit(fuel.current_fuel, max_refuel_cap)
	else:
		is_refueling = false


## Localiza o FuelComponent na hierarquia da aeronave.
##
## Args:
##     node (Node): Instancia a ser inspecionada recursivamente.
##
## Returns:
##     FuelComponent: Componente encontrado ou null.
func _find_fuel_component(node: Node) -> FuelComponent:
	if node == null:
		return null
	var comp: FuelComponent = node.get_node_or_null("FuelComponent") as FuelComponent
	if comp != null:
		return comp
	for child in node.get_children():
		if child is FuelComponent:
			return child
	return null


## Callback disparado quando a aeronave entra na area do posto.
##
## Args:
##     body (Node3D): Corpo que colidiu com o gatilho.
##
## Returns:
##     void
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "PlayerHelicopter":
		player_helicopter = body


## Callback disparado quando a aeronave decola ou abandona o perimetro do posto.
##
## Args:
##     body (Node3D): Corpo que saiu do gatilho.
##
## Returns:
##     void
func _on_body_exited(body: Node3D) -> void:
	if body == player_helicopter:
		player_helicopter = null
		is_refueling = false
