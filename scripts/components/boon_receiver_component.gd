## Componente receptor e gerenciador de Boons taticos na aeronave do jogador.
##
## Aplica modificadores percentuais e aditivos nos componentes de voo, blindagem,
## combustivel, armamento e resgate, alem de suportar contramedidas (Chaff/Flare).
class_name BoonReceiverComponent
extends Node

## Referencias aos subsistemas da aeronave para aplicacao de modificadores.
@export var flight_controller: FlightMovementController
@export var health_component: HealthComponent
@export var fuel_component: FuelComponent
@export var cargo_component: CargoComponent
@export var weapon_manager: WeaponManager
@export var rescue_sensor: Node

## Lista de boons atualmente ativos durante a incursao corrente.
var active_boons: Array[BoonData] = []

## Flag indicando se o sistema de Chaff/Flare automatico esta habilitado.
var auto_chaff_enabled: bool = false

## Tempo de recarga total do sistema de contramedidas (em segundos).
var chaff_cooldown: float = 12.0

## Cronometro interno do tempo de recarga de Chaff.
var chaff_timer: float = 0.0

## Dicionario de valores originais salvos antes da aplicacao de modificadores.
var _original_values: Dictionary = {}

## Catalogo de boons indexados por ID para facil resolucao via sinais.
var _boons_catalog: Dictionary = {}


## Inicializa o componente, resolve referencias aos componentes irmaos se necessario
## e conecta ao sinal de aplicacao de boons do EventBus.
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
	_resolve_subsystems()
	_load_default_boons_catalog()
	
	if EventBus != null and not EventBus.boon_applied.is_connected(_on_event_bus_boon_applied):
		EventBus.boon_applied.connect(_on_event_bus_boon_applied)


## Atualiza o cronometro interno de recarga das contramedidas de Chaff/Flare.
##
## Args:
##     delta (float): Intervalo de tempo do frame em segundos.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	if chaff_timer > 0.0:
		chaff_timer = maxf(0.0, chaff_timer - delta)
	
	if auto_chaff_enabled and chaff_timer <= 0.0:
		_check_incoming_homing_threats()


## Tenta acionar uma contramedida de Chaff/Flare automatica caso habilitada.
##
## Se acionado com sucesso, desvia e quebra o travamento de todos os misseis hostis
## teleguiados direcionados ao helicoptero no perimetro proximo.
##
## Args:
##     Nenhum.
##
## Returns:
##     bool: True se o Chaff foi disparado com sucesso, False se inativo ou em recarga.
##
## Raises:
##     Nenhuma excecao levantada.
func try_trigger_chaff() -> bool:
	if not auto_chaff_enabled:
		return false
	if chaff_timer > 0.0:
		return false
	chaff_timer = chaff_cooldown
	_deploy_chaff_countermeasures()
	return true


## Verifica se ha ameacas de misseis teleguiados hostis travados no helicoptero.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _check_incoming_homing_threats() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	
	var missiles: Array[Node] = tree.get_nodes_in_group("homing_missiles")
	for m in missiles:
		if m is Projectile and is_instance_valid(m):
			var proj: Projectile = m as Projectile
			if proj.is_homing and proj.source != parent_node:
				if proj.homing_target == parent_node or (parent_node is Node3D and (parent_node as Node3D).is_inside_tree() and proj.is_inside_tree() and proj.global_position.distance_to((parent_node as Node3D).global_position) <= 35.0):
					try_trigger_chaff()
					return


## Desvia e neutraliza o teleguiamento de misseis hostis proximos a aeronave.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _deploy_chaff_countermeasures() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	
	var parent_node: Node = get_parent()
	var origin: Vector3 = Vector3.ZERO
	if parent_node is Node3D and (parent_node as Node3D).is_inside_tree():
		origin = (parent_node as Node3D).global_position
	
	var missiles: Array[Node] = tree.get_nodes_in_group("homing_missiles")
	for m in missiles:
		if m is Projectile and is_instance_valid(m):
			var proj: Projectile = m as Projectile
			if proj.is_homing and proj.source != parent_node:
				var dist: float = 0.0
				if origin != Vector3.ZERO and proj.is_inside_tree():
					dist = proj.global_position.distance_to(origin)
				if dist <= 50.0:
					proj.break_homing_lock()
	
	if EventBus != null:
		EventBus.radio_transmission_requested.emit(
			"system",
			"SISTEMA",
			"Contramedidas Chaff/Flare liberadas! Travamento de missil hostil quebrado.",
			2.5
		)


## Aplica um BoonData aos componentes correspondentes da aeronave.
##
## Args:
##     boon (BoonData): Recurso contendo parametros e modificadores a aplicar.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func apply_boon(boon: BoonData) -> void:
	if boon == null:
		return
	
	_resolve_subsystems()
	active_boons.append(boon)
	
	# Modificador principal
	_apply_property_modifier(
		boon.target_property_name,
		boon.operation,
		boon.value,
		boon.target_system
	)
	
	# Modificador secundario opcional
	if boon.has_secondary_buff and not boon.secondary_property_name.is_empty():
		_apply_property_modifier(
			boon.secondary_property_name,
			boon.secondary_operation,
			boon.secondary_value,
			boon.target_system
		)
	
	# Penalidade (drawback) opcional
	if boon.has_drawback and not boon.drawback_property_name.is_empty():
		_apply_property_modifier(
			boon.drawback_property_name,
			BoonData.OperationType.MULTIPLY,
			boon.drawback_value,
			boon.target_system
		)


## Aplica um boon buscando pelo seu identificador textual no catalogo.
##
## Args:
##     boon_id (String): Identificador unico do boon (ex: "overclock_rotor").
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func apply_boon_by_id(boon_id: String) -> void:
	if _boons_catalog.has(boon_id):
		apply_boon(_boons_catalog[boon_id])
	else:
		var loaded: Resource = _try_load_boon_by_id(boon_id)
		if loaded is BoonData:
			apply_boon(loaded as BoonData)


## Restaura todas as variaveis modificadas para seus valores originais de fabrica
## e limpa o historico de boons ativos da incursao.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func reset_boons() -> void:
	for key: String in _original_values:
		var parts: PackedStringArray = key.split(":")
		if parts.size() == 2:
			var obj: Object = _get_object_by_system_name(parts[0])
			var prop: String = parts[1]
			if obj != null and prop in obj:
				obj.set(prop, _original_values[key])
	
	_original_values.clear()
	active_boons.clear()
	auto_chaff_enabled = false
	chaff_timer = 0.0


## Localiza o objeto alvo responsavel por uma determinada propriedade.
##
## Args:
##     property_name (String): Nome da propriedade.
##     suggested_system (BoonData.TargetSystem): Sistema sugerido pelo schema.
##
## Returns:
##     Object: Objeto responsavel ou null se nao encontrado.
##
## Raises:
##     Nenhuma excecao levantada.
func _find_target_object(property_name: String, suggested_system: BoonData.TargetSystem) -> Object:
	# Prioriza o sistema sugerido
	match suggested_system:
		BoonData.TargetSystem.FLIGHT:
			if flight_controller != null and property_name in flight_controller:
				return flight_controller
		BoonData.TargetSystem.ARMOR:
			if health_component != null and property_name in health_component:
				return health_component
		BoonData.TargetSystem.FUEL:
			if fuel_component != null and property_name in fuel_component:
				return fuel_component
		BoonData.TargetSystem.WEAPONS:
			if weapon_manager != null and property_name in weapon_manager:
				return weapon_manager
		BoonData.TargetSystem.RESCUE:
			if cargo_component != null and property_name in cargo_component:
				return cargo_component
			if rescue_sensor != null and property_name in rescue_sensor:
				return rescue_sensor
	
	# Fallback de busca em todos os subsistemas
	var candidates: Array[Object] = [
		flight_controller,
		health_component,
		fuel_component,
		cargo_component,
		weapon_manager,
		rescue_sensor,
		self,
	]
	
	for candidate: Object in candidates:
		if candidate != null and property_name in candidate:
			return candidate
			
	return null


## Aplica a operacao matematica sobre uma propriedade protegendo contra divisoes por zero.
##
## Args:
##     property_name (String): Nome da variavel alvo.
##     operation (BoonData.OperationType): Tipo da operacao (MULTIPLY, ADD, UNLOCK_FLAG).
##     value (float): Valor numerico ou modificador.
##     suggested_system (BoonData.TargetSystem): Dica de sistema alvo.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _apply_property_modifier(
	property_name: String,
	operation: BoonData.OperationType,
	value: float,
	suggested_system: BoonData.TargetSystem
) -> void:
	if not is_finite(value):
		return
	
	var target_obj: Object = _find_target_object(property_name, suggested_system)
	if target_obj == null or not (property_name in target_obj):
		return
	
	var obj_key: String = "%s:%s" % [_get_system_name_for_object(target_obj), property_name]
	var current_val: Variant = target_obj.get(property_name)
	
	# Salva o valor original apenas no primeiro modificador aplicado nesta propriedade
	if not _original_values.has(obj_key):
		_original_values[obj_key] = current_val
	
	match operation:
		BoonData.OperationType.MULTIPLY:
			if current_val is float or current_val is int:
				var new_val: float = float(current_val) * value
				if not is_finite(new_val):
					return
				# Protecao contra valores menores ou iguais a zero em duracao e velocidade
				if property_name in ["boarding_duration", "max_speed", "acceleration", "max_fuel", "max_health"]:
					new_val = maxf(0.01, new_val)
				if current_val is int:
					target_obj.set(property_name, int(round(new_val)))
				else:
					target_obj.set(property_name, new_val)
		
		BoonData.OperationType.ADD:
			if current_val is float or current_val is int:
				var new_val: float = float(current_val) + value
				if not is_finite(new_val):
					return
				if current_val is int:
					target_obj.set(property_name, int(round(new_val)))
				else:
					target_obj.set(property_name, new_val)
					
				# Se expandir capacidade maxima de tanque, atualiza a quantidade corrente se cabivel
				if property_name == "max_fuel" and fuel_component != null:
					fuel_component.refuel(value)
				elif property_name == "max_health" and health_component != null:
					health_component.repair(value)
		
		BoonData.OperationType.UNLOCK_FLAG:
			target_obj.set(property_name, true)


## Resolve ponteiros para os componentes irmaos ou pais caso nao injetados.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _resolve_subsystems() -> void:
	var root: Node = get_parent() if get_parent() != null else self
	
	if flight_controller == null and root.has_node("FlightMovementController"):
		flight_controller = root.get_node("FlightMovementController") as FlightMovementController
	if health_component == null and root.has_node("HealthComponent"):
		health_component = root.get_node("HealthComponent") as HealthComponent
	if fuel_component == null and root.has_node("FuelComponent"):
		fuel_component = root.get_node("FuelComponent") as FuelComponent
	if cargo_component == null and root.has_node("CargoComponent"):
		cargo_component = root.get_node("CargoComponent") as CargoComponent
	if weapon_manager == null and root.has_node("WeaponManager"):
		weapon_manager = root.get_node("WeaponManager") as WeaponManager
	if rescue_sensor == null and root.has_node("RescueSensorArea"):
		rescue_sensor = root.get_node("RescueSensorArea")


## Retorna a representacao em texto do sistema para chaveamento de cache.
##
## Args:
##     obj (Object): Objeto alvo.
##
## Returns:
##     String: Identificador do sistema.
##
## Raises:
##     Nenhuma excecao levantada.
func _get_system_name_for_object(obj: Object) -> String:
	if obj == flight_controller:
		return "flight"
	elif obj == health_component:
		return "health"
	elif obj == fuel_component:
		return "fuel"
	elif obj == cargo_component:
		return "cargo"
	elif obj == weapon_manager:
		return "weapon"
	elif obj == rescue_sensor:
		return "rescue_sensor"
	return "self"


## Obtem o objeto correspondente ao nome do sistema.
##
## Args:
##     system_name (String): Identificador textual do sistema.
##
## Returns:
##     Object: Objeto correspondente ou null.
##
## Raises:
##     Nenhuma excecao levantada.
func _get_object_by_system_name(system_name: String) -> Object:
	match system_name:
		"flight":
			return flight_controller
		"health":
			return health_component
		"fuel":
			return fuel_component
		"cargo":
			return cargo_component
		"weapon":
			return weapon_manager
		"rescue_sensor":
			return rescue_sensor
		"self":
			return self
	return null


## Carrega catalogo de boons taticos padrao do jogo.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _load_default_boons_catalog() -> void:
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
				var boon: BoonData = res as BoonData
				_boons_catalog[boon.id] = boon


## Tenta carregar sob demanda um boon pelo seu id.
##
## Args:
##     boon_id (String): Identificador unico do boon.
##
## Returns:
##     Resource: Recurso carregado ou null.
##
## Raises:
##     Nenhuma excecao levantada.
func _try_load_boon_by_id(boon_id: String) -> Resource:
	var path: String = "res://scripts/data/boon_%s.tres" % boon_id
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


## Callback acionado pelo EventBus ao aplicar um boon.
##
## Args:
##     boon_id (String): Identificador unico do boon selecionado.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_event_bus_boon_applied(boon_id: String) -> void:
	apply_boon_by_id(boon_id)
