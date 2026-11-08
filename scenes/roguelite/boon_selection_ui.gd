## Interface modal de selecao de Boons taticos em Blackout Strike.
##
## Pausa o jogo ao abrir via EventBus.data_crate_opened, apresenta 3 opcoes de melhorias
## taticas e aplica a escolha selecionada no helicóptero antes de retomar a simulacao.
class_name BoonSelectionUI
extends Control

## Sinal emitido localmente ao selecionar uma opcao de Boon.
signal boon_chosen(boon: BoonData)

## Referencias aos nós da interface.
@onready var cards_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CardsContainer
@onready var modal_title: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel

## Boons atualmente exibidos nas 3 cartas.
var current_options: Array = []


## Inicializa a UI, oculta a tela modal e conecta ao EventBus global.
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if EventBus != null and not EventBus.data_crate_opened.is_connected(open_selection):
		EventBus.data_crate_opened.connect(open_selection)


## Abre o modal com a lista de 3 boons recebida e pausa o fluxo da arvore de cena.
##
## Args:
##     boons (Array): Lista contendo os recursos BoonData sorteados.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func open_selection(boons: Array) -> void:
	current_options = boons.duplicate()
	_populate_cards()
	visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true


## Preenche as cartas de exibicao com titulos, descricoes e botoes de confirmacao.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _populate_cards() -> void:
	if cards_container == null:
		return
	
	# Limpa cartas anteriores
	for child: Node in cards_container.get_children():
		child.queue_free()
	
	for i in range(current_options.size()):
		var boon_item: Variant = current_options[i]
		if not (boon_item is BoonData):
			continue
		var boon: BoonData = boon_item as BoonData
		var card: PanelContainer = _create_card_panel(boon, i)
		cards_container.add_child(card)


## Cria dinamicamente a estrutura visual de uma carta de Boon.
##
## Args:
##     boon (BoonData): Recurso contendo informacoes da melhoria.
##     index (int): Indice da opcao selecionavel.
##
## Returns:
##     PanelContainer: Nó da carta pronto para montagem.
##
## Raises:
##     Nenhuma excecao levantada.
func _create_card_panel(boon: BoonData, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 280)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title_lbl: Label = Label.new()
	title_lbl.text = boon.title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title_lbl)
	
	var desc_lbl: Label = Label.new()
	desc_lbl.text = boon.description
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)
	
	var btn: Button = Button.new()
	btn.text = "INSTALAR FIRMWARE"
	btn.pressed.connect(select_option.bind(index))
	vbox.add_child(btn)
	
	return card


## Confirma a escolha de um dos Boons, emite notificacoes e despausa a arvore de cena.
##
## Args:
##     index (int): Indice da opcao escolhida.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func select_option(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return
	
	var chosen: Variant = current_options[index]
	if not (chosen is BoonData):
		return
	var boon: BoonData = chosen as BoonData
	
	visible = false
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
	
	if GameState != null and not GameState.active_run_boons.has(boon.id):
		GameState.active_run_boons.append(boon.id)
	
	if EventBus != null:
		EventBus.boon_applied.emit(boon.id)
	
	boon_chosen.emit(boon)
