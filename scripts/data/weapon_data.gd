## Recurso de configuracao e balanceamento de armamentos.
##
## Armazena parametros de identificacao, balistica, cadencia e comportamento teleguiado
## para os slots de armas da aeronave.
class_name WeaponData
extends Resource

@export_group("Identificacao")
@export var id: String = "vulcan_20mm"
@export var display_name: String = "Canhao Rotativo Vulcan"
@export var icon: Texture2D

@export_group("Propriedades de Balistica")
@export var projectile_scene: PackedScene
@export var max_ammo: int = 1200
@export var fire_rate: float = 12.0
@export var base_damage: float = 14.0
@export var projectile_speed: float = 120.0
@export var spread_angle_deg: float = 2.0
@export var explosion_radius: float = 0.0

@export_group("Teleguiamento")
@export var is_homing: bool = false
@export var homing_cone_deg: float = 40.0
@export var homing_turn_speed: float = 6.0
