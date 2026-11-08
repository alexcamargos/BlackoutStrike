## Recurso de balanceamento e comportamento das entidades hostis e estruturas do jogo.
##
## Parametriza vida, velocidade, alcance de deteccao, cadencia e caracteristicas balisticas.
class_name EnemyStatsData
extends Resource

enum BehaviorType {
	STATIC_TURRET,
	GROUND_PATROL,
	NAVAL_PATROL,
	AIR_INTERCEPTOR,
}

@export var id: String = "turret_sam"
@export var display_name: String = "Bateria Antiaerea SAM"
@export var behavior: BehaviorType = BehaviorType.STATIC_TURRET
@export var collision_layer: int = 3
@export var max_health: float = 240.0
@export var move_speed: float = 0.0
@export var detection_range: float = 40.0
@export var fire_interval: float = 4.0
@export var projectile_damage: float = 180.0
@export var projectile_speed: float = 28.0
@export var projectile_explosion_radius: float = 0.0
@export var is_homing_projectile: bool = true
@export var suppresses_rescue_ring: bool = false
@export var suppression_radius: float = 10.0
@export var supply_drop_chance: float = 0.35
