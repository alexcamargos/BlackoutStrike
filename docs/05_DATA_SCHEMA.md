# 05_DATA_SCHEMA.md: Especificação de Recursos Customizados (`CustomResource`)

Para evitar valores mágicos dispersos pelo código-fonte, todos os parâmetros de balanceamento de armas, aprimoramentos e características de inimigos são serializados como instâncias de `Resource` (`.tres`).

---

## 1. Esquema de Definição de Armas (`WeaponData.gd`)

```gdscript
# res://scripts/data/weapon_data.gd
class_name WeaponData
extends Resource

@export_group("Identificação")
@export var id: String = "vulcan_20mm"
@export var display_name: String = "Canhão Rotativo Vulcan"
@export var icon: Texture2D

@export_group("Propriedades de Balística")
@export var projectile_scene: PackedScene
@export var max_ammo: int = 1200
@export var fire_rate: float = 12.0 # Disparos por segundo
@export var base_damage: float = 14.0
@export var projectile_speed: float = 120.0 # Metros por segundo
@export var spread_angle_deg: float = 2.0 # Dispersão em graus
@export var explosion_radius: float = 0.0 # Maior que 0 gera dano em área

@export_group("Teleguiamento")
@export var is_homing: bool = false
@export var homing_cone_deg: float = 40.0
@export var homing_turn_speed: float = 6.0 # Radianos por segundo
```

---

## 2. Esquema de Boons de Incursão Roguelite (`BoonData.gd`)

```gdscript
# res://scripts/data/boon_data.gd
class_name BoonData
extends Resource

enum TargetSystem {
    FLIGHT,       # Velocidade, inércia, arrasto
    ARMOR,        # HP, recuperação no heliponto
    FUEL,         # Consumo passivo e aceleração
    WEAPONS,      # Dano, cadência, penetração
    RESCUE        # Tempo de embarque, raio do sensor
}

enum OperationType {
    MULTIPLY,     # Modificador percentual (ex: 1.15 para +15%)
    ADD,          # Modificador aditivo linear (ex: +25 HP)
    UNLOCK_FLAG   # Habilita uma funcionalidade (ex: chaff_automatico = true)
}

@export var id: String = "overclock_turbina"
@export var title: String = "Overclock de Rotor"
@export_multiline var description: String = "+15% Velocidade Máxima e Aceleração, porém +10% Consumo de Combustível."
@export var icon: Texture2D
@export var target_system: TargetSystem = TargetSystem.FLIGHT
@export var operation: OperationType = OperationType.MULTIPLY
@export var target_property_name: String = "max_speed"
@export var value: float = 1.15

# Modificador sinérgico adicional (opcional, ex: aumentar max_speed e acceleration juntos)
@export var has_secondary_buff: bool = true
@export var secondary_property_name: String = "acceleration"
@export var secondary_operation: OperationType = OperationType.MULTIPLY
@export var secondary_value: float = 1.15

# Modificador de penalidade (para balanceamento com trade-offs)
@export var has_drawback: bool = true
@export var drawback_property_name: String = "active_burn_rate"
@export var drawback_value: float = 1.10
```

---

## 3. Esquema de Progressão Permanente do Hangar (`HangarUpgradeData.gd`)

```gdscript
# res://scripts/data/hangar_upgrade_data.gd
class_name HangarUpgradeData
extends Resource

@export var id: String = "expand_cabin"
@export var title: String = "Cabine Estendida"
@export_multiline var description: String = "Aumenta permanentemente a capacidade de reféns do R-9X."
@export var current_level: int = 0
@export var max_level: int = 3
@export var cost_per_level: Array[int] = [3, 6, 12] # Custo em Sobreviventes Extraídos
@export var value_per_level: Array[float] = [6.0, 7.0, 8.0] # Valor resultante ou bônus por nível
```

---

## 4. Esquema de Especificações Base da Aeronave (`HelicopterSpecsData.gd`)

```gdscript
# res://scripts/data/helicopter_specs_data.gd
class_name HelicopterSpecsData
extends Resource

@export_group("Sobrevivência e Cabine")
@export var max_armor: float = 1000.0
@export var max_fuel: float = 100.0
@export var passive_burn_rate: float = 0.7
@export var active_burn_rate: float = 1.6
@export var autorotation_grace_seconds: float = 3.0
@export var max_cargo: int = 5
@export var rescue_boarding_time: float = 2.0
@export var rescue_max_altitude: float = 1.2

@export_group("Cinemática de Voo")
@export var acceleration: float = 18.0
@export var max_speed: float = 22.0
@export var drag_deceleration: float = 7.5
@export var cruise_altitude: float = 4.0
@export var hover_altitude: float = 0.8
@export var max_tilt_deg: float = 22.0
@export var yaw_turn_speed: float = 8.0
```

---

## 5. Esquema de Entidades Hostis e Estruturas (`EnemyStatsData.gd` e `ShelterData.gd`)

```gdscript
# res://scripts/data/enemy_stats_data.gd
class_name EnemyStatsData
extends Resource

enum BehaviorType {
    STATIC_TURRET,    # Sentinela fixa (ex: TurretSAM)
    GROUND_PATROL,    # Patrulha terrestre por waypoints (ex: MercenarySquad, LightTank_IFV)
    NAVAL_PATROL,     # Patrulha aquática costeira/lagoa (ex: PatrolBoat)
    AIR_INTERCEPTOR   # Perseguidor aéreo na Camada 4 (ex: HunterDrone)
}

@export var id: String = "turret_sam"
@export var display_name: String = "Bateria Antiaérea SAM"
@export var behavior: BehaviorType = BehaviorType.STATIC_TURRET
@export var collision_layer: int = 3 # 3 = Enemies_Ground, 4 = Enemies_Air
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
```

```gdscript
# res://scripts/data/shelter_data.gd
class_name ShelterData
extends Resource

@export var id: String = "rescue_shelter_standard"
@export var max_health: float = 300.0
@export var survivor_count: int = 4
@export var survivor_max_health: float = 30.0
@export var spawn_scatter_radius: float = 2.5
```

---

## 6. Tabela de Balanceamento Inicial do MVP (Valores Base)

| ID do Recurso | Tipo | Propriedade | Valor Base | Notas |
| :--- | :--- | :--- | :--- | :--- |
| `weapon_vulcan.tres` | `WeaponData` | `base_damage` | $14.0$ | Efetivo contra infantaria, drones, mísseis e alvos leves. |
| `weapon_vulcan.tres` | `WeaponData` | `max_ammo` | $1200$ | Cadência contínua de $12\text{ tiros/s}$. |
| `weapon_hydra.tres` | `WeaponData` | `base_damage` | $160.0$ | Dano balístico em raio de $3.0\text{ m}$ (fere civis expostos). |
| `weapon_hydra.tres` | `WeaponData` | `max_ammo` | $32$ | Disparo rápido em salvas duplas. |
| `weapon_hellfire.tres`| `WeaponData` | `base_damage` | $650.0$ | Trava no alvo via cone de $40^\circ$. |
| `weapon_hellfire.tres`| `WeaponData` | `max_ammo` | $6$ | Foco em tanques, torretas pesadas e canhoneiro. |
| `helicopter_specs.tres`| `HelicopterSpecsData` | `max_armor` | $1000.0$ | Blindagem integral base do R-9X. |
| `helicopter_specs.tres`| `HelicopterSpecsData` | `max_fuel` | $150.0$ | Autonomia: 300s passivo / 125s aceleração total. |
| `map_bounds_midway.tres`| `MapBoundsData` | `world_size` | $2500 \times 2500$ | Limites globais de [-1250, 1250] no plano horizontal. |
| `helicopter_specs.tres`| `HelicopterSpecsData` | `max_cargo` | $5$ | Limite base de sobreviventes por sortida. |
| `rescue_shelter.tres` | `ShelterData` | `max_health` | $300.0$ | Libera $4$ sobreviventes ($30.0\text{ HP}$ cada) ao ser destruído. |
| `enemy_mercenary_squad.tres` | `EnemyStatsData` | `max_health` | $45.0$ | `GROUND_PATROL` ($3.5\text{ m/s}$), dano $12.0$, suprime resgate ($\le 10\text{ m}$). |
| `enemy_hunter_drone.tres` | `EnemyStatsData` | `max_health` | $60.0$ | `AIR_INTERCEPTOR` Camada 4 ($14.0\text{ m/s}$), rajada a cada $1.5\text{ s}$ (dano $20.0$). |
| `enemy_patrol_boat.tres` | `EnemyStatsData` | `max_health` | $180.0$ | `NAVAL_PATROL` ($8.0\text{ m/s}$), rajada a cada $2.0\text{ s}$ (dano $35.0$). |
| `enemy_light_tank.tres` | `EnemyStatsData` | `max_health` | $320.0$ | `GROUND_PATROL` ($4.5\text{ m/s}$), obus $95.0$ (raio $2.0\text{ m}$), suprime resgate. |
| `enemy_turret_sam.tres` | `EnemyStatsData` | `max_health` | $240.0$ | `STATIC_TURRET`, alcance $40\text{ m}$, míssil a cada $4.0\text{ s}$ (dano $180.0$). |
| `data_crate.tres` | `EnemyStatsData` | `max_health` | $150.0$ | Ao zerar HP, emite `EventBus.data_crate_opened`. |

---

## 7. Esquema de Delimitação Espacial e Setores (`MapBoundsData.gd`)

```gdscript
# res://scripts/data/map_bounds_data.gd
class_name MapBoundsData
extends Resource

@export_group("Dimensoes Globais do Mundo")
@export var world_size: Vector2 = Vector2(2500.0, 2500.0)
@export var world_bounds_min: Vector2 = Vector2(-1250.0, -1250.0)
@export var world_bounds_max: Vector2 = Vector2(1250.0, 1250.0)

@export_group("Macrozona Terrestre (Atol Central)")
@export var atoll_rect: Rect2 = Rect2(-600.0, -400.0, 1200.0, 800.0)
@export var shelter_spawn_rect: Rect2 = Rect2(-500.0, -350.0, 1000.0, 700.0)

@export_group("Pontos Estrategicos de Spawn")
@export var vanguard_spawn_position: Vector3 = Vector3(800.0, 1.0, 950.0)
@export var boss_spawn_position: Vector3 = Vector3(-900.0, 0.0, -900.0)
@export var north_platform_position: Vector3 = Vector3(200.0, 0.0, -1000.0)
@export var sigint_reef_position: Vector3 = Vector3(900.0, 0.0, 100.0)
@export var fob_depot_position: Vector3 = Vector3(-250.0, 0.5, 120.0)
```
