## Recurso de configuracao e balanceamento de abrigos de refens.
##
## Armazena parametros de identificacao, integridade estrutural, contagem de sobreviventes,
## vida dos civis e raio de dispersao ao romper a estrutura.
class_name ShelterData
extends Resource

## Identificador unico do tipo de abrigo.
@export var id: String = "rescue_shelter_standard"

## Integridade estrutural maxima do abrigo (HP).
@export var max_health: float = 300.0

## Quantidade de civis abrigados liberados ao destruir o edificio.
@export var survivor_count: int = 4

## Pontos de vida maximos de cada civil liberado no solo.
@export var survivor_max_health: float = 30.0

## Raio de dispersao radial (em metros) onde os sobreviventes sao gerados ao redor da fundacao.
@export var spawn_scatter_radius: float = 2.5
