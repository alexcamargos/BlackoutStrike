## Interface de Usuario (HUD) tatica no estilo retro-moderno militar.
##
## Exibe barras de blindagem e combustivel, selecao e contagem de municao
## dos tres slots de armas, alerta de cabine lotada e status de travamento teleguiado.
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
@onready var lock_indicator: PanelContainer = $CenterScreen/LockIndicator

## Indice da arma ativa atualmente na interface.
var active_slot_index: int = 0


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


## Atualiza os valores nominais da barra de integridade estrutural.
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


## Atualiza a barra de combustivel e ajusta a cor em caso de reserva critica.
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
	fuel_label.text = "FUEL: %d%%" % [int((current / maxf(1.0, max_fuel)) * 100.0)]


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


## Notifica a contagem de sobreviventes a bordo e ativa alerta de cabine lotada.
##
## Args:
##     current_cargo (int): Quantidade de passageiros embarcados.
##     max_cargo (int): Limite fisico da cabine do helicóptero.
##
## Returns:
##     void
func _on_civilian_boarded(current_cargo: int, max_cargo: int) -> void:
	cargo_label.text = "PASSENGERS: %d / %d" % [current_cargo, max_cargo]
	cabin_full_alert.visible = (current_cargo >= max_cargo)


## Notifica a conclusao de entrega de sobreviventes ao Heliponto Aliado.
##
## Args:
##     total_rescued (int): Total acumulado de especialistas extraidos.
##
## Returns:
##     void
func _on_civilian_extracted(_total_rescued: int) -> void:
	cargo_label.text = "PASSENGERS: 0 / 5"
	cabin_full_alert.visible = false


## Habilita o indicador visual de reticula de travamento do Hellfire.
##
## Args:
##     _target (Node3D): Instancia do alvo adquirido.
##
## Returns:
##     void
func _on_target_locked(_target: Node3D) -> void:
	lock_indicator.visible = true


## Oculta o indicador de travamento teleguiado.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_target_lost() -> void:
	lock_indicator.visible = false


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
			slot_panels[i].modulate = Color(0.6, 0.65, 0.7, 0.6) # Desativado / translúcido
