## Interface de Usuario (HUD) tatica militar de alta fidelidade (estilo VC-06).
##
## Implementa os 7 modulos contratados da interface de combate:
## 1. Top-Left: Barras angulares segmentadas de blindagem e combustivel com insignias vetoriais.
## 2. Top-Center: Fita de azimute e bussola militar com entalhe trapezoidal.
## 3. Top-Right: Manifesto de sobreviventes com pips e alerta diegetico CABIN FULL.
## 4. Bottom-Left: Radar tatico de superficie com varredura circular e plotagem de contatos.
## 5. Bottom-Center: Horizonte artificial e atitude de voo com silhueta vetorial do R-9X.
## 6. Bottom-Right: Baia de armamento empilhada com slots ativos e medidores segmentados.
## 7. CenterScreen: Reticula circular tatica com travas de alvo e marcador em losango.
##
## Conecta-se exclusivamente atraves dos sinais do EventBus.
class_name HUD
extends Control

# --- Modulo 1: Blindagem e Combustivel (Top-Left) ---
@onready var health_bar: ProgressBar = $TopLeft/VBox/HealthBar
@onready var fuel_bar: ProgressBar = $TopLeft/VBox/FuelBar
@onready var health_label: Label = $TopLeft/VBox/HealthBar/HealthLabel
@onready var fuel_label: Label = $TopLeft/VBox/FuelBar/FuelLabel

# --- Modulo 6: Baia de Armamento (Bottom-Right) ---
@onready var slot_panels: Array[PanelContainer] = [
	get_node("BottomRight/WeaponSlots/Slot0") as PanelContainer,
	get_node("BottomRight/WeaponSlots/Slot1") as PanelContainer,
	get_node("BottomRight/WeaponSlots/Slot2") as PanelContainer
]
@onready var slot_backdrops: Array[ColorRect] = [
	get_node_or_null("BottomRight/WeaponSlots/Slot0/Backdrop") as ColorRect,
	get_node_or_null("BottomRight/WeaponSlots/Slot1/Backdrop") as ColorRect,
	get_node_or_null("BottomRight/WeaponSlots/Slot2/Backdrop") as ColorRect
]
@onready var slot_contents: Array[Control] = [
	get_node_or_null("BottomRight/WeaponSlots/Slot0/Margin") as Control,
	get_node_or_null("BottomRight/WeaponSlots/Slot1/Margin") as Control,
	get_node_or_null("BottomRight/WeaponSlots/Slot2/Margin") as Control
]
@onready var ammo_labels: Array[Label] = [
	get_node("BottomRight/WeaponSlots/Slot0/Margin/HBox/VBox/HeaderRow/AmmoLabel") as Label,
	get_node("BottomRight/WeaponSlots/Slot1/Margin/HBox/VBox/HeaderRow/AmmoLabel") as Label,
	get_node("BottomRight/WeaponSlots/Slot2/Margin/HBox/VBox/HeaderRow/AmmoLabel") as Label
]
@onready var name_labels: Array[Label] = [
	get_node("BottomRight/WeaponSlots/Slot0/Margin/HBox/VBox/HeaderRow/NameLabel") as Label,
	get_node("BottomRight/WeaponSlots/Slot1/Margin/HBox/VBox/HeaderRow/NameLabel") as Label,
	get_node("BottomRight/WeaponSlots/Slot2/Margin/HBox/VBox/HeaderRow/NameLabel") as Label
]
@onready var ammo_bars: Array[ProgressBar] = [
	get_node_or_null("BottomRight/WeaponSlots/Slot0/Margin/HBox/VBox/AmmoBar") as ProgressBar,
	get_node_or_null("BottomRight/WeaponSlots/Slot1/Margin/HBox/VBox/AmmoBar") as ProgressBar,
	get_node_or_null("BottomRight/WeaponSlots/Slot2/Margin/HBox/VBox/AmmoBar") as ProgressBar
]

# --- Modulo 3: Resgate e Passageiros (Top-Right) ---
@onready var cargo_label: Label = $TopRight/VBox/CargoContainer/HBox/CargoLabel
@onready var cabin_full_alert: Label = $TopRight/VBox/CabinFullAlert
@onready var passenger_pips_container: HBoxContainer = $TopRight/VBox/PassengerPips

# --- Modulo 7: Reticula e Lock-On (CenterScreen) ---
@onready var lock_indicator: PanelContainer = $CenterScreen/LockIndicator
@onready var reticle_rect: ColorRect = $CenterScreen/ReticleCenter/ReticleRect
@onready var lock_target_box: ColorRect = get_node_or_null("CenterScreen/LockIndicator/VBox/LockTargetBox") as ColorRect

# --- Modulo 2: Bussola Tática e Rumo (Top-Center) ---
@onready var compass_panel: PanelContainer = get_node_or_null("TopCenter/VBox/TacticalCompass") as PanelContainer if has_node("TopCenter/VBox/TacticalCompass") else get_node_or_null("TopCenter/TacticalCompass") as PanelContainer
@onready var compass_label: Label = get_node_or_null("TopCenter/VBox/TacticalCompass/CompassLabel") as Label if has_node("TopCenter/VBox/TacticalCompass/CompassLabel") else get_node_or_null("TopCenter/TacticalCompass/CompassLabel") as Label
@onready var heading_tape_rect: ColorRect = get_node_or_null("TopCenter/VBox/HeadingTape") as ColorRect if has_node("TopCenter/VBox/HeadingTape") else get_node_or_null("TopCenter/HeadingTape") as ColorRect

# --- Modulo 4 & 5: Radar e Horizonte Artificial ---
@onready var radar_widget: Control = get_node_or_null("BottomLeft/RadarPanel/Margin/TacticalRadar") as Control
@onready var attitude_widget: Control = get_node_or_null("BottomCenter/AttitudeHorizon") as Control

## Indice da arma ativa atualmente na interface.
var active_slot_index: int = 0

## Capacidade maxima de passageiros informada dinamicamente pelo componente de carga.
var max_passenger_capacity: int = 5

## Quantidade de civis a bordo da cabine.
var current_cargo_count: int = 0

## Referencia rastreada da aeronave do jogador.
var _tracked_player: Node3D = null

## Referencia ao alvo atualmente travado pelo míssil Hellfire.
var _locked_target: Node3D = null


## Conecta o HUD aos eventos do EventBus e inicializa o layout visual 1080p.
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


## Atualiza os valores nominais e o shader segmentado de 8 blocos da blindagem.
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


## Atualiza a barra angular segmentada de combustivel e seu shader âmbar.
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


## Atualiza a contagem de municao e a barra segmentada do slot correspondente.
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
	
	if slot_index >= 0 and slot_index < ammo_bars.size():
		var bar: ProgressBar = ammo_bars[slot_index]
		if bar != null:
			bar.max_value = max_ammo
			bar.value = current
			if bar.material is ShaderMaterial:
				var ratio: float = clampf(float(current) / maxf(1.0, float(max_ammo)), 0.0, 1.0)
				(bar.material as ShaderMaterial).set_shader_parameter("fill_ratio", ratio)


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


## Sincroniza a exibicao dos pips graficos de passageiros embarcados em estilo militar.
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
	
	while passenger_pips_container.get_child_count() < total:
		var pip: Panel = Panel.new()
		pip.custom_minimum_size = Vector2(18.0, 14.0)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.196, 0.839, 1.0, 1.0)
		style.border_color = Color(0.196, 0.839, 1.0, 0.95)
		style.set_border_width_all(1)
		pip.add_theme_stylebox_override("panel", style)
		passenger_pips_container.add_child(pip)
	
	while passenger_pips_container.get_child_count() > total:
		var last_child: Node = passenger_pips_container.get_child(passenger_pips_container.get_child_count() - 1)
		passenger_pips_container.remove_child(last_child)
		last_child.queue_free()
	
	for i in range(passenger_pips_container.get_child_count()):
		var pip: Control = passenger_pips_container.get_child(i) as Control
		if pip != null:
			if i < current:
				pip.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				pip.modulate = Color(0.25, 0.45, 0.55, 0.30)


## Habilita o indicador visual de reticula de travamento e a moldura do alvo com losango.
##
## Args:
##     target (Node3D): Instancia do alvo adquirido.
##
## Returns:
##     void
func _on_target_locked(target: Node3D) -> void:
	_locked_target = target
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
	_locked_target = null
	lock_indicator.visible = false
	if reticle_rect != null and reticle_rect.material is ShaderMaterial:
		(reticle_rect.material as ShaderMaterial).set_shader_parameter("is_locked", false)


## Modifica a borda e o contraste para distinguir o armamento ativo dos inativos conforme VC-06.
##
## Args:
##     active_idx (int): Indice do slot a ser enfatizado.
##
## Returns:
##     void
func _highlight_active_slot(active_idx: int) -> void:
	for i in range(slot_panels.size()):
		var is_active: bool = (i == active_idx)
		if i < slot_backdrops.size() and slot_backdrops[i] != null and slot_backdrops[i].material is ShaderMaterial:
			var smat: ShaderMaterial = slot_backdrops[i].material as ShaderMaterial
			if is_active:
				smat.set_shader_parameter("border_color", Color(0.196, 0.839, 1.0, 1.0))
				smat.set_shader_parameter("border_width", 2.0)
				smat.set_shader_parameter("fill_color", Color(0.05, 0.14, 0.24, 0.86))
			else:
				smat.set_shader_parameter("border_color", Color(0.196, 0.839, 1.0, 0.35))
				smat.set_shader_parameter("border_width", 1.2)
				smat.set_shader_parameter("fill_color", Color(0.04, 0.10, 0.17, 0.65))
		if i < slot_contents.size() and slot_contents[i] != null:
			slot_contents[i].modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.75, 0.85, 0.92, 0.55)


func _process(_delta: float) -> void:
	if _tracked_player == null or not is_instance_valid(_tracked_player):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_tracked_player = players[0] as Node3D
	
	if _tracked_player != null and is_instance_valid(_tracked_player):
		_update_tactical_compass(_tracked_player.global_position)
		if heading_tape_rect != null and heading_tape_rect.material is ShaderMaterial:
			var heading_yaw: float = _tracked_player.rotation.y
			(heading_tape_rect.material as ShaderMaterial).set_shader_parameter("heading_offset", heading_yaw * 2.0)
	
	_update_target_lock_position()


## Atualiza a posicao do marcador de lock-on em tela sobre o alvo travado.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _update_target_lock_position() -> void:
	if lock_indicator == null or not lock_indicator.visible:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null and _locked_target != null and is_instance_valid(_locked_target) and not cam.is_position_behind(_locked_target.global_position):
		var screen_pos: Vector2 = cam.unproject_position(_locked_target.global_position)
		var vp_size: Vector2 = get_viewport_rect().size
		var half_size: Vector2 = lock_indicator.size * 0.5
		lock_indicator.position = Vector2(
			clampf(screen_pos.x - half_size.x, 24.0, vp_size.x - lock_indicator.size.x - 24.0),
			clampf(screen_pos.y - half_size.y, 24.0, vp_size.y - lock_indicator.size.y - 24.0)
		)
	else:
		var vp_size: Vector2 = get_viewport_rect().size
		lock_indicator.position = (vp_size - lock_indicator.size) * 0.5


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
	
	if current_cargo_count > 0:
		var dist_vanguard: float = Vector2(pos.x - vanguard_pos.x, pos.z - vanguard_pos.z).length()
		var card_vanguard: String = get_cardinal_direction(pos, vanguard_pos)
		var arrow_vanguard: String = get_direction_arrow(card_vanguard)
		compass_label.text = "%s BASE VANGUARD [%s] %dm (EVACUACAO)" % [arrow_vanguard, card_vanguard, int(dist_vanguard)]
		compass_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		return
	
	var dist_midway: float = Vector2(pos.x, pos.z).length()
	if dist_midway > 450.0:
		var card_midway: String = get_cardinal_direction(pos, midway_center)
		var arrow_midway: String = get_direction_arrow(card_midway)
		if dist_midway > 1250.0:
			compass_label.text = "%s ATOL DE MIDWAY [%s] %dm [⚠ DESVIO: VIRE W+A]" % [arrow_midway, card_midway, int(dist_midway)]
			compass_label.modulate = Color(1.0, 0.45, 0.2, 1.0)
		else:
			compass_label.text = "%s ATOL DE MIDWAY [%s] %dm" % [arrow_midway, card_midway, int(dist_midway)]
			compass_label.modulate = Color(0.0, 0.95, 0.85, 1.0)
	else:
		compass_label.text = "● ATOL DE MIDWAY [SETOR TERRESTRE]"
		compass_label.modulate = Color(0.3, 0.95, 0.4, 1.0)


## Converte a sigla cardinal em seta de navegacao para o plano de tela.
##
## Args:
##     cardinal (String): Sigla da direcao cardinal (ex: NW, SE, N).
##
## Returns:
##     String: Icone de seta direcional orientada para o vetor da tela.
func get_direction_arrow(cardinal: String) -> String:
	match cardinal:
		"N": return "↑"
		"NE": return "↗"
		"E": return "→"
		"SE": return "↘"
		"S": return "↓"
		"SW": return "↙"
		"W": return "←"
		"NW": return "↖"
		_: return "▲"


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
