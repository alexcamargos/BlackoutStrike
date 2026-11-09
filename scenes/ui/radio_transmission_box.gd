## Caixa de dialogo de transmissao de radio militar (estilo radio chatter).
##
## Conecta-se ao EventBus.radio_transmission_requested para exibir mensagens,
## indicativos de chamada, retratos dos interlocutores com scanlines e auto-ocultar-se.
class_name RadioTransmissionBox
extends Control

const PORTRAIT_CROSS: Texture2D = preload("res://assets/textures/ui/portrait_cross.tres")
const PORTRAIT_VANE: Texture2D = preload("res://assets/textures/ui/portrait_vane.tres")
const PORTRAIT_VANCE: Texture2D = preload("res://assets/textures/ui/portrait_vance.tres")

@onready var callsign_label: Label = $PanelContainer/Margin/HBox/VBox/Header/CallsignLabel
@onready var message_label: Label = $PanelContainer/Margin/HBox/VBox/MessageLabel
@onready var portrait_rect: TextureRect = $PanelContainer/Margin/HBox/PortraitContainer/Portrait
@onready var scanlines_overlay: ColorRect = $PanelContainer/Margin/HBox/PortraitContainer/ScanlinesOverlay

## Cronometro de permanencia da mensagem na tela em segundos.
var display_timer: float = 0.0

## Duracao total solicitada para a transmissao corrente.
var target_duration: float = 4.0


## Inicializa o componente conectando ao EventBus e ocultando a caixa.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	visible = false
	if EventBus != null:
		EventBus.radio_transmission_requested.connect(_on_radio_transmission_requested)


## Gerencia o tempo de permanencia da mensagem e executa a auto-ocultacao.
##
## Args:
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func _process(delta: float) -> void:
	if not visible:
		return
	
	display_timer += delta
	if display_timer >= target_duration:
		visible = false


## Recebe requisicao de chatter militar e formata a interface com o texto e retrato emitido.
##
## Args:
##     speaker_id (String): Identificador unico do personagem.
##     callsign (String): Indicativo de chamada de radio militar (ex: COM. VANCE).
##     message (String): Texto descritivo transmitido.
##     duration (float): Tempo em segundos para exibicao.
##
## Returns:
##     void
func _on_radio_transmission_requested(speaker_id: String, callsign: String, message: String, duration: float) -> void:
	callsign_label.text = callsign
	message_label.text = message
	target_duration = duration if duration > 0.0 else 4.0
	display_timer = 0.0
	
	var sid_lower: String = speaker_id.to_lower()
	if sid_lower.contains("cross") or sid_lower.contains("rook") or sid_lower.contains("ghost"):
		portrait_rect.texture = PORTRAIT_CROSS
	elif sid_lower.contains("vane") or sid_lower.contains("apex"):
		portrait_rect.texture = PORTRAIT_VANE
	else:
		portrait_rect.texture = PORTRAIT_VANCE
	
	visible = true
