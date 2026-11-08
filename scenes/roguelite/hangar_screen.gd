## Interface de gerenciamento do Hangar e compra de upgrades de meta-progressao.
##
## Conecta-se ao MetaProgression.gd permitindo adquirir melhorias permanentes
## com Personnel Tokens e iniciar novas incursoes no jogo.
class_name HangarScreen
extends Control

## Sinal emitido ao concluir a compra de uma melhoria.
signal upgrade_purchased(upgrade_id: String, new_level: int)

## Sinal emitido ao clicar para decolar em uma nova missao.
signal mission_launch_requested()

## Colecao de recursos de aprimoramento gerenciados pelo Hangar.
@export var upgrade_resources: Array[HangarUpgradeData] = []

## Referencias aos nós da interface.
@onready var tokens_label: Label = $MarginContainer/VBoxContainer/Header/TokensLabel
@onready var upgrades_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/UpgradesList
@onready var launch_button: Button = $MarginContainer/VBoxContainer/Footer/LaunchButton


## Inicializa a tela de hangar carregando upgrades padrao e montando os componentes visuais.
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
	if upgrade_resources.is_empty():
		_load_default_upgrades()
	
	if launch_button != null and not launch_button.pressed.is_connected(on_launch_pressed):
		launch_button.pressed.connect(on_launch_pressed)
	
	refresh_ui()


## Atualiza os rotulos de saldo de tokens e o estado de cada cartao de aprimoramento.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func refresh_ui() -> void:
	if MetaProgression != null and tokens_label != null:
		tokens_label.text = "FICHAS DE PESSOAL DISPONIVEIS: %d" % MetaProgression.personnel_tokens
	
	if upgrades_container == null:
		return
	
	for child: Node in upgrades_container.get_children():
		child.queue_free()
	
	for upgrade: HangarUpgradeData in upgrade_resources:
		var panel: PanelContainer = _build_upgrade_card(upgrade)
		upgrades_container.add_child(panel)


## Tenta adquirir uma melhoria permanente pelo seu identificador.
##
## Args:
##     upgrade_id (String): Chave identificadora do upgrade.
##
## Returns:
##     bool: True se a transacao foi bem-sucedida, False caso contrario.
##
## Raises:
##     Nenhuma excecao levantada.
func purchase_upgrade_by_id(upgrade_id: String) -> bool:
	for upgrade: HangarUpgradeData in upgrade_resources:
		if upgrade.id == upgrade_id:
			if MetaProgression != null and MetaProgression.purchase_upgrade(upgrade):
				refresh_ui()
				upgrade_purchased.emit(upgrade.id, MetaProgression.get_upgrade_level(upgrade.id))
				return true
			return false
	return false


## Aciona o pedido de lancamento de missao, resetando estados temporarios de run.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func on_launch_pressed() -> void:
	if GameState != null:
		GameState.start_new_run()
	mission_launch_requested.emit()


## Constroi dinamicamente o painel visual correspondente a um upgrade de hangar.
##
## Args:
##     upgrade (HangarUpgradeData): Recurso com configuracoes do aprimoramento.
##
## Returns:
##     PanelContainer: Nó montado com textos, niveis e botao de compra.
##
## Raises:
##     Nenhuma excecao levantada.
func _build_upgrade_card(upgrade: HangarUpgradeData) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var current_lvl: int = MetaProgression.get_upgrade_level(upgrade.id) if MetaProgression != null else 0
	
	var title_lbl: Label = Label.new()
	title_lbl.text = "%s (Nivel %d/%d)" % [upgrade.title, current_lvl, upgrade.max_level]
	info_vbox.add_child(title_lbl)
	
	var desc_lbl: Label = Label.new()
	desc_lbl.text = upgrade.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vbox.add_child(desc_lbl)
	
	var btn_vbox: VBoxContainer = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_vbox)
	
	var cost_lbl: Label = Label.new()
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var buy_btn: Button = Button.new()
	buy_btn.custom_minimum_size = Vector2(160, 42)
	
	var can_buy: bool = MetaProgression != null and MetaProgression.can_afford_upgrade(upgrade)
	if current_lvl >= upgrade.max_level:
		cost_lbl.text = "MAXIMIZADO"
		buy_btn.text = "NIVEL MAXIMO"
		buy_btn.disabled = true
	else:
		var cost: int = upgrade.cost_per_level[current_lvl] if current_lvl < upgrade.cost_per_level.size() else 0
		cost_lbl.text = "CUSTO: %d TOKENS" % cost
		buy_btn.text = "APRIMORAR"
		buy_btn.disabled = not can_buy
		buy_btn.pressed.connect(purchase_upgrade_by_id.bind(upgrade.id))
	
	btn_vbox.add_child(cost_lbl)
	btn_vbox.add_child(buy_btn)
	
	return card


## Carrega os tres recursos tres das melhorias de hangar.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _load_default_upgrades() -> void:
	var paths: Array[String] = [
		"res://scripts/data/upgrade_expand_cabin.tres",
		"res://scripts/data/upgrade_reinforce_armor.tres",
		"res://scripts/data/upgrade_ammo_logistics.tres",
	]
	for path: String in paths:
		if ResourceLoader.exists(path):
			var res: Resource = ResourceLoader.load(path)
			if res is HangarUpgradeData:
				upgrade_resources.append(res as HangarUpgradeData)
