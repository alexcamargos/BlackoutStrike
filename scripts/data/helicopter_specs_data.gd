## Recurso de especificacoes e parametros base da aeronave do jogador (R-9X Mohawk III).
##
## Centraliza constantes de voo, sobrevivencia, consumo de combustivel e capacidade de cabine.
class_name HelicopterSpecsData
extends Resource

@export_group("Sobrevivencia e Cabine")
@export var max_armor: float = 1000.0
@export var max_fuel: float = 100.0
@export var passive_burn_rate: float = 0.7
@export var active_burn_rate: float = 1.6
@export var autorotation_grace_seconds: float = 3.0
@export var max_cargo: int = 5
@export var rescue_boarding_time: float = 2.0
@export var rescue_max_altitude: float = 1.2

@export_group("Cinematica de Voo")
@export var acceleration: float = 18.0
@export var max_speed: float = 22.0
@export var drag_deceleration: float = 7.5
@export var cruise_altitude: float = 4.0
@export var hover_altitude: float = 0.8
@export var max_tilt_deg: float = 22.0
@export var yaw_turn_speed: float = 8.0
