## Terreno litoraneo modular e relevo topografico do Atol de Midway.
##
## Implementa as tres cotas altimetricas da ilha: praia rasa litoranea,
## plato industrial plano e falesias rochosas colidiveis.
class_name IslandTerrainMidway
extends StaticBody3D

## Alturas de referencia para as 3 cotas topograficas (em metros).
const BEACH_MIN_Y: float = -0.2
const BEACH_MAX_Y: float = 0.3
const PLATEAU_Y: float = 0.5
const CLIFF_MIN_Y: float = 0.5
const CLIFF_MAX_Y: float = 6.0

## Referencias opcionais a nos de relevo para inspecao e telemetria.
@export var plateau_mesh: MeshInstance3D
@export var beach_mesh: MeshInstance3D
@export var cliffs_container: Node3D


## Inicializa o corpo estatico do terreno, garantindo pertencimento aos grupos fisicos.
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
	if not is_in_group("world_static"):
		add_to_group("world_static")
	collision_layer = 1
	collision_mask = 0


## Retorna a cota nominal aproximada do terreno para coordenadas do plano XZ.
##
## Args:
##     x (float): Coordenada espacial X no mundo.
##     z (float): Coordenada espacial Z no mundo.
##
## Returns:
##     float: Altitude nominal da superficie na posicao fornecida.
##
## Raises:
##     Nenhuma excecao levantada.
func get_surface_altitude(x: float, z: float) -> float:
	# Regiao da falesia rochosa do setor nordeste
	if x >= 5.0 and x <= 25.0 and z >= 4.0 and z <= 20.0:
		return 5.0
	# Regiao da falesia rochosa do setor oeste
	if x >= -121.0 and x <= -103.0 and z >= -28.0 and z <= 8.0:
		return 5.5
	# Regiao da falesia rochosa do setor leste
	if x >= 94.0 and x <= 116.0 and z >= -69.0 and z <= -41.0:
		return 5.7
	# Regiao da falesia rochosa do setor sul
	if x >= -59.0 and x <= -31.0 and z >= 71.0 and z <= 89.0:
		return 4.5
	# Limites externos da ilha (faixa de praia litoranea)
	if absf(x) > 120.0 or absf(z) > 120.0:
		return 0.1
	# Plato industrial principal
	return PLATEAU_Y
