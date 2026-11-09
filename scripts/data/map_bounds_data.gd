## Recurso de definicao dos limites geograficos, setores e pontos estrategicos do mapa.
##
## Centraliza dimensoes de mundo, retangulos de confinamento (Bounding Boxes) e coordenadas de spawn.
class_name MapBoundsData
extends Resource

@export_group("Dimensoes Globais do Mundo")
## Dimensao horizontal total do mapa em metros (largura X, profundidade Z).
@export var world_size: Vector2 = Vector2(2500.0, 2500.0)

## Coordenada minima do mundo no plano horizontal (X min, Z min).
@export var world_bounds_min: Vector2 = Vector2(-1250.0, -1250.0)

## Coordenada maxima do mundo no plano horizontal (X max, Z max).
@export var world_bounds_max: Vector2 = Vector2(1250.0, 1250.0)

@export_group("Macrozona Terrestre (Atol Central)")
## Retangulo delimitador da massa territorial principal do Atol (posicao X/Z e tamanho).
@export var atoll_rect: Rect2 = Rect2(-600.0, -400.0, 1200.0, 800.0)

## Mascara restrita para sorteio de abrigos de civis dentro do Atol.
@export var shelter_spawn_rect: Rect2 = Rect2(-500.0, -350.0, 1000.0, 700.0)

@export_group("Pontos Estrategicos de Spawn")
## Coordenadas de decolagem do jogador na pista do porta-avioes USS Vanguard (Setor Sudeste).
@export var vanguard_spawn_position: Vector3 = Vector3(800.0, 1.0, 950.0)

## Coordenadas da nau-capitania canhoneira Apex Bastion (Setor Noroeste - Aguas Profundas).
@export var boss_spawn_position: Vector3 = Vector3(-900.0, 0.0, -900.0)

## Coordenadas da plataforma de dados maritima (Setor Norte).
@export var north_platform_position: Vector3 = Vector3(200.0, 0.0, -1000.0)

## Coordenadas do posto de escuta SIGINT nos recifes orientais (Setor Leste).
@export var sigint_reef_position: Vector3 = Vector3(900.0, 0.0, 100.0)

## Coordenadas do posto avancado de reabastecimento terrestre FOB (Setor Central).
@export var fob_depot_position: Vector3 = Vector3(-250.0, 0.5, 120.0)


## Verifica se uma coordenada 3D reside dentro dos limites mundiais horizontais.
##
## Args:
##     position (Vector3): Coordenadas espaciais globais a verificar.
##
## Returns:
##     bool: True se o ponto estiver dentro das bordas mundiais; False caso contrario.
func is_inside_world(position: Vector3) -> bool:
	return (
		position.x >= world_bounds_min.x
		and position.x <= world_bounds_max.x
		and position.z >= world_bounds_min.y
		and position.z <= world_bounds_max.y
	)


## Verifica se uma coordenada 3D reside dentro da mascara de geracao de abrigos do Atol.
##
## Args:
##     position (Vector3): Coordenadas espaciais a verificar.
##
## Returns:
##     bool: True se o ponto residir no retangulo de abrigos; False caso contrario.
func is_inside_shelter_area(position: Vector3) -> bool:
	return shelter_spawn_rect.has_point(Vector2(position.x, position.z))
