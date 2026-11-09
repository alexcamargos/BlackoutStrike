## Interface de Usuario (HUD) tatica no estilo retro-moderno militar.
##
## Exibe barras angulares segmentadas de blindagem e combustivel, selecao e contagem de municao
## dos tres slots de armas, indicadores de contagem de passageiros (pips), alerta de cabine lotada
## e reticula tatica com feedback de travamento de alvos.
## Conecta-se exclusivamente atraves dos sinais do EventBus.
class_name HUD
extends Control

@onready var health_bar: ProgressBar = $TopLeft/VBox/HealthBar
@onready var fuel_bar: ProgressBar = $TopLeft/VBox/FuelBar
@onready var health_label: Label = $TopLeft/VBox/HealthBar/HealthLabel
@onready var fuel_label: Label = $TopLeft/VBox/FuelBar/FuelLabel

@onready var slot_panels: Array[PanelContainer] = [
	$BottomLeft/WeaponSlots/Slot0,
	$BottomLeft/WeaponSlots/Slot1,
	$BottomLeft/WeaponSlots/Slot2
]
@onready var ammo_labels: Array[Label] = [
	$BottomLeft/WeaponSlots/Slot0/VBox/AmmoLabel,
	$BottomLeft/WeaponSlots/Slot1/VBox/AmmoLabel,
	$BottomLeft/WeaponSlots/Slot2/VBox/AmmoLabel
]
@onready var name_labels: Array[Label] = [
	$BottomLeft/WeaponSlots/Slot0/VBox/NameLabel,
	$BottomLeft/WeaponSlots/Slot1/VBox/NameLabel,
	$BottomLeft/WeaponSlots/Slot2/VBox/NameLabel
]

@onready var cargo_label: Label = $TopRight/VBox/CargoContainer/CargoLabel
@onready var cabin_full_alert: Label = $TopRight/VBox/CabinFullAlert
@onready var passenger_pips_container: HBoxContainer = $TopRight/VBox/PassengerPips
@onready var lock_indicator: PanelContainer = $CenterScreen/VBox/LockIndicator
@onready var reticle_rect: ColorRect = $CenterScreen/VBox/ReticleRect
@onready var compass_panel: PanelContainer = get_node_or_null("TopCenter/TacticalCompass") as PanelContainer
@onready var compass_label: Label = get_node_or_null("TopCenter/TacticalCompass/CompassLabel") as Label


## Indice da arma ativa atualmente na interface.
var active_slot_index: int = 0

## Capacidade maxima de passageiros informada dinamicamente pelo componente de carga.
var max_passenger_capacity: int = 5

## Quantidade de civis a bordo da cabine.
var current_cargo_count: int = 0

## Referencia rastreada da aeronave do jogador.
var _tracked_player: Node3D = null


## Conecta o HUD aos eventos do EventBus e configura os estados visuais iniciais.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	cabin_full_alert.visible = false
	lock_indicator.visible = false
	_highlight_active_slot(0)
	_update_passenger_pips(0, max_passenger_capacity)
	
	if EventBus == null:
		return
	
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_fuel_changed.connect(_on_fuel_changed)
	EventBus.weapon_selected.connect(_on_weapon_selected)
	EventBus.weapon_ammo_changed.connect(_on_weapon_ammo_changed)
	EventBus.civilian_boarded.connect(_on_civilian_boarded)
	EventBus.civilian_extracted.connect(_on_civilian_extracted)
	EventBus.target_locked.connect(_on_target_locked)
	EventBus.target_lost.connect(_on_target_lost)


## Atualiza os valores nominais e o shader segmentado da integridade estrutural.
##
## Args:
##     current (float): Pontos de integridade restantes.
##     max_health (float): Capacidade nominal maxima.
##
## Returns:
##     void
func _on_health_changed(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "ARMOR: %d / %d" % [int(current), int(max_health)]
	if health_bar.material is ShaderMaterial:
		var ratio: float = clampf(current / maxf(1.0, max_health), 0.0, 1.0)
		(health_bar.material as ShaderMaterial).set_shader_parameter("fill_ratio", ratio)


## Atualiza a barra angular segmentada de combustivel e seu shader.
##
## Args:
##     current (float): Unidades restantes de combustivel.
##     max_fuel (float): Capacidade do tanque da aeronave.
##
## Returns:
##     void
func _on_fuel_changed(current: float, max_fuel: float) -> void:
	fuel_bar.max_value = max_fuel
	fuel_bar.value = current
	var ratio: float = clampf(current / maxf(1.0, max_fuel), 0.0, 1.0)
	fuel_label.text = "FUEL: %d%%" % [int(ratio * 100.0)]
	if fuel_bar.material is ShaderMaterial:
		(fuel_bar.material as ShaderMaterial).set_shader_parameter("fill_ratio", ratio)


## Atualiza o destaque visual do slot de armamento selecionado.
##
## Args:
##     slot_index (int): Indice do slot ativado (0 a 2).
##     weapon_name (String): Nome descritivo do armamento.
##
## Returns:
##     void
func _on_weapon_selected(slot_index: int, _weapon_name: String) -> void:
	active_slot_index = slot_index
	_highlight_active_slot(slot_index)


## Atualiza a contagem de municao no mostrador do slot correspondente.
##
## Args:
##     slot_index (int): Indice do slot afetado.
##     current (int): Municao remanescente.
##     max_ammo (int): Limite do compartimento de municao.
##
## Returns:
##     void
func _on_weapon_ammo_changed(slot_index: int, current: int, max_ammo: int) -> void:
	if slot_index >= 0 and slot_index < ammo_labels.size():
		ammo_labels[slot_index].text = "%d / %d" % [current, max_ammo]


## Notifica a contagem de sobreviventes a bordo, pips segmentados e ativa alerta de lotacao.
##
## Args:
##     current_cargo (int): Quantidade de passageiros embarcados.
##     max_cargo (int): Limite fisico da cabine do helicóptero.
##
## Returns:
##     void
func _on_civilian_boarded(current_cargo: int, max_cargo: int) -> void:
	current_cargo_count = current_cargo
	max_passenger_capacity = max_cargo
	cargo_label.text = "PASSENGERS: %d / %d" % [current_cargo, max_cargo]
	cabin_full_alert.visible = (current_cargo >= max_cargo)
	_update_passenger_pips(current_cargo, max_cargo)


## Notifica a conclusao de entrega de sobreviventes ao Heliponto Aliado.
##
## Args:
##     total_rescued (int): Total acumulado de especialistas extraidos.
##
## Returns:
##     void
func _on_civilian_extracted(_total_rescued: int) -> void:
	current_cargo_count = 0
	cargo_label.text = "PASSENGERS: 0 / %d" % [max_passenger_capacity]
	cabin_full_alert.visible = false
	_update_passenger_pips(0, max_passenger_capacity)


## Sincroniza a exibicao dos pips graficos de passageiros embarcados.
##
## Args:
##     current (int): Quantidade de ocupantes atuais.
##     total (int): Capacidade total da cabine.
##
## Returns:
##     void
func _update_passenger_pips(current: int, total: int) -> void:
	if passenger_pips_container == null:
		return
	
	# Ajusta a quantidade de blocos indicadores para a capacidade total
	while passenger_pips_container.get_child_count() < total:
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = Vector2(16.0, 10.0)
		passenger_pips_container.add_child(pip)
	
	while passenger_pips_container.get_child_count() > total:
		var last_child: Node = passenger_pips_container.get_child(passenger_pips_container.get_child_count() - 1)
		passenger_pips_container.remove_child(last_child)
		last_child.queue_free()
	
	# Atualiza o estado de ativacao (aceso vs vazio)
	for i in range(passenger_pips_container.get_child_count()):
		var pip: Control = passenger_pips_container.get_child(i) as Control
		if pip != null:
			if i < current:
				pip.modulate = Color(0.2, 0.9, 0.85, 1.0)
			else:
				pip.modulate = Color(0.2, 0.3, 0.4, 0.25)


## Habilita o indicador visual de reticula de travamento do Hellfire.
##
## Args:
##     _target (Node3D): Instancia do alvo adquirido.
##
## Returns:
##     void
func _on_target_locked(_target: Node3D) -> void:
	lock_indicator.visible = true
	if reticle_rect != null and reticle_rect.material is ShaderMaterial:
		(reticle_rect.material as ShaderMaterial).set_shader_parameter("is_locked", true)


## Oculta o indicador de travamento teleguiado e reseta a reticula de mira.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_target_lost() -> void:
	lock_indicator.visible = false
	if reticle_rect != null and reticle_rect.material is ShaderMaterial:
		(reticle_rect.material as ShaderMaterial).set_shader_parameter("is_locked", false)


## Modifica a modulacao de cor para distinguir o armamento ativo dos inativos.
##
## Args:
##     active_idx (int): Indice do slot a ser enfatizado.
##
## Returns:
##     void
func _highlight_active_slot(active_idx: int) -> void:
	for i in range(slot_panels.size()):
		if i == active_idx:
			slot_panels[i].modulate = Color(1.0, 0.85, 0.2, 1.0) # Ambar ativo
		else:
			slot_panels[i].modulate = Color(0.6, 0.65, 0.7, 0.6) # Desativado / translucido


func _process(_delta: float) -> void:
	if compass_label == null:
		return
	
	if _tracked_player == null or not is_instance_valid(_tracked_player):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_tracked_player = players[0] as Node3D
	
	if _tracked_player != null and is_instance_valid(_tracked_player):
		_update_tactical_compass(_tracked_player.global_position)


## Atualiza o mostrador tatico de navegacao com indicacao cardinal e distancia.
##
## Args:
##     pos (Vector3): Coordenadas espaciais atuais do jogador no mundo.
##
## Returns:
##     void
func _update_tactical_compass(pos: Vector3) -> void:
	if compass_label == null:
		return
	
	var vanguard_pos: Vector3 = Vector3(800.0, 0.0, 950.0)
	var midway_center: Vector3 = Vector3(0.0, 0.0, 0.0)
	
	# Se a cabine contem civis para desembarcar, prioriza a base de evacuacao USS Vanguard
	if current_cargo_count > 0:
		var dist_vanguard: float = Vector2(pos.x - vanguard_pos.x, pos.z - vanguard_pos.z).length()
		var card_vanguard: String = get_cardinal_direction(pos, vanguard_pos)
		compass_label.text = "⚓ BASE VANGUARD [%s] %dm (EVACUACAO)" % [card_vanguard, int(dist_vanguard)]
		compass_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		return
	
	# Caso contrario, calcula a rota para o Atol Central de Midway
	var dist_midway: float = Vector2(pos.x, pos.z).length()
	if dist_midway > 450.0:
		var card_midway: String = get_cardinal_direction(pos, midway_center)
		compass_label.text = "▲ ATOL DE MIDWAY [%s] %dm" % [card_midway, int(dist_midway)]
		compass_label.modulate = Color(0.0, 0.95, 0.85, 1.0)
	else:
		compass_label.text = "● ATOL DE MIDWAY [SETOR TERRESTRE]"
		compass_label.modulate = Color(0.3, 0.9, 0.4, 1.0)


## Converte o vetor entre dois pontos no plano XZ em direcao cardinal (N, NE, E, SE, S, SW, W, NW).
##
## Args:
##     from (Vector3): Posicao de origem.
##     to (Vector3): Posicao de destino.
##
## Returns:
##     String: Rosa dos ventos com a sigla cardinal.
func get_cardinal_direction(from: Vector3, to: Vector3) -> String:
	var dx: float = to.x - from.x
	var dz: float = to.z - from.z
	var angle: float = rad_to_deg(atan2(dz, dx))
	var heading: float = fposmod(angle + 90.0, 360.0)
	if heading >= 337.5 or heading < 22.5:
		return "N"
	elif heading < 67.5:
		return "NE"
	elif heading < 112.5:
		return "E"
	elif heading < 157.5:
		return "SE"
	elif heading < 202.5:
		return "S"
	elif heading < 247.5:
		return "SW"
	elif heading < 292.5:
		return "W"
	else:
		return "NW"
