## Entidade de deposito de firmware e dados taticos (DataCrate).
##
## Armazena 150.0 HP de blindagem; ao ser destruida, sorteia 3 Boons taticos unicos
## e emite EventBus.data_crate_opened para abrir o modal de aprimoramento roguelite.
class_name DataCrate
extends StaticBody3D

## Recurso de estatisticas da caixa de dados.
@export var stats_data: EnemyStatsData

## Lista customizada de boons disponiveis para sorteio (caso vazia, carrega o catalogo padrao).
@export var available_boons: Array[BoonData] = []

## Referencia ao componente de integridade.
@onready var health_component: HealthComponent = $HealthComponent

## Flag para evitar detonação duplicada.
var is_opened: bool = false


## Inicializa a caixa de dados, configurando grupos de fisica e integridade nominal.
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
	add_to_group("enemies")
	add_to_group("structures")
	add_to_group("data_crates")
	
	if stats_data == null:
		stats_data = preload("res://scripts/data/data_crate.tres")
	
	if available_boons.is_empty():
		_load_default_boons()
	
	if health_component != null and stats_data != null:
		health_component.max_health = stats_data.max_health
		health_component.current_health = stats_data.max_health
		health_component.entity_destroyed.connect(_on_entity_destroyed)


## Aplica dano a caixa de dados redirecionando ao HealthComponent.
##
## Args:
##     amount (float): Quantidade de dano recebido.
##     source (Node3D): Origem do ataque (opcional).
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func take_damage(amount: float, source: Node3D = null) -> void:
	if health_component != null and not is_opened:
		health_component.take_damage(amount, source)


## Sorteia 3 Boons distintos dentre as opcoes disponiveis.
##
## Args:
##     count (int): Quantidade de boons a sortear (padrao: 3).
##
## Returns:
##     Array[BoonData]: Lista com os boons sorteados sem repeticao.
##
## Raises:
##     Nenhuma excecao levantada.
func draw_random_boons(count: int = 3) -> Array[BoonData]:
	var pool: Array[BoonData] = available_boons.duplicate()
	pool.shuffle()
	
	var drawn: Array[BoonData] = []
	var limit: int = mini(count, pool.size())
	for i in range(limit):
		drawn.append(pool[i])
	return drawn


## Callback acionado na destruicao da caixa de dados ao zerar seus pontos de vida.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_entity_destroyed() -> void:
	if is_opened:
		return
	is_opened = true
	
	var drawn_boons: Array[BoonData] = draw_random_boons(3)
	if EventBus != null:
		EventBus.data_crate_opened.emit(drawn_boons)
	
	queue_free()


## Carrega catalogo padrao dos 5 Boons do MVP caso nao fornecidos.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _load_default_boons() -> void:
	var paths: Array[String] = [
		"res://scripts/data/boon_overclock_rotor.tres",
		"res://scripts/data/boon_armor_piercing_ammo.tres",
		"res://scripts/data/boon_high_power_winch.tres",
		"res://scripts/data/boon_auxiliary_fuel_tanks.tres",
		"res://scripts/data/boon_chaff_flare_system.tres",
	]
	for path: String in paths:
		if ResourceLoader.exists(path):
			var res: Resource = ResourceLoader.load(path)
			if res is BoonData:
				available_boons.append(res as BoonData)
