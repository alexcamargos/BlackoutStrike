# 04_ARCHITECTURE.md: Árvore de Cenas, Hierarquia e Contratos de Comunicação

## 1. Visão Arquitetural

O projeto utiliza o padrão de **Entidades Baseadas em Componentes** sobre o grafo de cena do Godot 4, integrado a um padrão **Mediator / EventBus** para desacoplamento de fluxos globais.

---

## 2. Camadas de Colisão no Espaço 3D (Collision Layers & Masks)

A correta configuração da matriz de física 3D previne varreduras de colisão desnecessárias e assegura a consistência das rotinas de dano:

| Camada | Nome | Descrição |
| :---: | :--- | :--- |
| **1** | `World_Static` | Terreno da ilha, falésias rochosas e construções indestrutíveis. |
| **2** | `Player_Air` | Fuselagem do helicóptero R-9X Mohawk III. |
| **3** | `Enemies_Ground` | Tanques, bunkers, torretas costeiras e o casco do chefe. |
| **4** | `Enemies_Air` | Drones e aeronaves hostis. |
| **5** | `Player_Projectiles` | Balas do canhão Vulcan, foguetes Hydra e mísseis Hellfire disparados pelo jogador. |
| **6** | `Enemy_Projectiles` | Tiros de torretas antiaéreas e mísseis teleguiados hostis. |
| **7** | `Civilians` | Especialistas aguardando evacuação no solo. |
| **8** | `Zones_Trigger` | Áreas de pouso de helipontos, caixas de reabastecimento e volumes de resgate. |

---

## 3. Diagrama Hierárquico da Cena Principal (`Mission_01_Midway.tscn`)

```text
Mission_01_Midway (Node3D)
├── WorldEnvironment (WorldEnvironment) [Perfil de Bloom, Tonemap Filmic, SSAO]
├── DirectionalLight3D [Sol tropical: iluminação quente, Cascaded Shadow Maps]
├── OceanWaterMesh (MeshInstance3D) [Plano horizontal infinito com ocean_pbr.gdshader]
├── IslandTerrain (StaticBody3D) [Malha de solo e rochas colidíveis na Camada 1]
│   └── CollisionShape3D
├── IslandProps (Node3D) [Instanciamento em lote de palmeiras, contêineres e guindastes via MultiMesh]
├── SpawnDirector (Node3D) [Script responsável pelo sorteio e spawn de POIs]
│   ├── ShelterSpawnPoints (Node3D)
│   ├── SAMSpawnPoints (Node3D)
│   └── DataCrateSpawnPoints (Node3D)
├── Helipads (Node3D)
│   └── AllyBaseHelipad (Area3D) [Camada 8: Cura, abastecimento e descarga]
├── ActiveEntities (Node3D)
│   ├── PlayerHelicopter (CharacterBody3D) [Instância do jogador]
│   ├── Enemies (Node3D) [Contêiner dinâmico de forças hostis]
│   │   ├── TurretSAM_Instances...
│   │   └── BossApexBastion (Node3D)
│   └── Civilians (Node3D) [Contêiner de instâncias de sobreviventes liberados]
├── TacticalCamera (Camera3D) [Posição orbital inclinada a 68°, FOV 36°, script de seguimento suave]
└── CanvasLayer_UI (CanvasLayer)
    ├── HUD (Control) [Barras de recursos, tacômetros e radares de missão]
    ├── BoonSelectionModal (Control) [Exibição de cartas de aprimoramento roguelite]
    └── RadioTransmissionBox (Control) [Caixa de diálogo militar estilo chatter]
```

---

## 4. Estrutura Interna da Entidade do Jogador (`PlayerHelicopter.tscn`)

```text
PlayerHelicopter (CharacterBody3D) [Camada 2 | Máscaras: 1, 3, 4, 6, 8]
├── CollisionShape3D [Cápsula ou caixa de colisão da fuselagem]
├── HelicopterMeshContainer (Node3D) [Nó intermediário para inclinação cosmética Roll/Pitch]
│   ├── FuselageMesh (MeshInstance3D) [Material PBR metálico com reflexos]
│   ├── MainRotor (MeshInstance3D) [Rotação contínua no eixo Y via código/shader]
│   ├── TailRotor (MeshInstance3D) [Rotação contínua no eixo X]
│   └── MuzzleMarkers (Node3D) [Pontos espaciais de saída de projéteis]
│       ├── VulcanMuzzle (Marker3D)
│       ├── HydraPodLeft (Marker3D)
│       ├── HydraPodRight (Marker3D)
│       └── HellfireHardpoint (Marker3D)
├── FlightMovementController (Node) [Script de física vetorial e cálculo de inércia]
├── HealthComponent (Node) [Script de controle de integridade de fuselagem]
├── FuelComponent (Node) [Script de consumo, estocagem e pane seca]
├── CargoComponent (Node) [Script de passageiros, limites e tempos de embarque]
├── WeaponManager (Node) [Script de slots, cadência e seleção balística]
├── BoonReceiverComponent (Node) [Aplica modificadores percentuais no voo/armas]
├── RescueSensorArea (Area3D) [Cilindro vertical projetado para baixo; detecta Camada 7]
│   └── CollisionShape3D
└── AudioPlayerHub (Node3D) [Reprodutores de áudio de motor, tiros e alarmes]
```

---

## 5. Contrato do Barramento Global de Eventos (`EventBus.gd`)

O singleton `EventBus` expõe sinais globais estritamente tipados:

```gdscript
# res://scripts/globals/event_bus.gd
extends Node

# Eventos de Recursos e Vida da Aeronave
signal player_health_changed(current: float, max_health: float)
signal player_fuel_changed(current: float, max_fuel: float)
signal player_fuel_depleted()
signal player_died(cause: String)

# Eventos de Arsenal e Balística
signal weapon_selected(slot_index: int, weapon_name: String)
signal weapon_ammo_changed(slot_index: int, current: int, max_ammo: int)
signal target_locked(target: Node3D)
signal target_lost()

# Eventos de Resgate e Sobrevivência
signal civilian_boarded(current_cargo: int, max_cargo: int)
signal civilian_extracted(total_rescued: int)
signal civilian_killed(total_lost: int)
signal rescue_zone_suppressed(is_suppressed: bool)
signal shelter_destroyed(shelter_position: Vector3, survivor_count: int)

# Eventos do Sistema Roguelite
signal data_crate_opened(available_boons: Array)
signal boon_applied(boon_id: String)

# Eventos do Chefe e Progressão de Missão
signal boss_phase_changed(boss_name: String, phase_index: int)
signal boss_defeated(boss_name: String)
signal mission_accomplished()
signal mission_failed(reason: String)

# Eventos de Narrativa e Transmissão de Rádio
signal radio_transmission_requested(speaker_id: String, callsign: String, message: String, duration: float)
```

---

## 6. Contratos Públicos dos Componentes (`res://scripts/components/`)

Para assegurar compatibilidade determinística com a suíte de testes GUT (`docs/08_TESTS.md`), todos os componentes de entidade implementam as assinaturas públicas abaixo:

### 6.1. `FuelComponent` (`res://scripts/components/fuel_component.gd`)
```gdscript
class_name FuelComponent
extends Node

signal fuel_changed(current: float, max_fuel: float)
signal fuel_depleted()

@export var max_fuel: float = 100.0
@export var current_fuel: float = 100.0
@export var passive_burn_rate: float = 0.7
@export var active_burn_rate: float = 1.6

func consume_passive(delta: float) -> void
func consume_active(delta: float) -> void
func refuel(amount: float) -> void
func is_empty() -> bool
```

### 6.2. `HealthComponent` (`res://scripts/components/health_component.gd`)
```gdscript
class_name HealthComponent
extends Node

signal health_changed(current: float, max_health: float)
signal entity_destroyed()

@export var max_health: float = 1000.0
@export var current_health: float = 1000.0
@export var is_invulnerable: bool = false

func take_damage(amount: float, source: Node3D = null) -> void
func repair(amount: float) -> void
```

### 6.3. `CargoComponent` (`res://scripts/components/cargo_component.gd`)
```gdscript
class_name CargoComponent
extends Node

signal passenger_boarded(current_occupants: int, max_capacity: int)
signal cabin_full()
signal passengers_unloaded(extracted_count: int)

@export var max_capacity: int = 5
@export var current_occupants: int = 0
@export var boarding_duration: float = 2.0

func try_board_passenger() -> bool
func unload_all() -> int
func is_full() -> bool
```

### 6.4. `FlightMovementController` (`res://scripts/components/flight_movement_controller.gd`)
```gdscript
class_name FlightMovementController
extends Node

@export var acceleration: float = 18.0
@export var max_speed: float = 22.0
@export var drag_deceleration: float = 7.5
@export var cruise_altitude: float = 4.0
@export var hover_altitude: float = 0.8
@export var altitude_transition_speed: float = 6.0
@export var max_tilt_deg: float = 22.0
@export var yaw_turn_speed: float = 8.0

func compute_velocity(current_velocity: Vector3, input_dir: Vector2, is_descending: bool, current_y: float, delta: float) -> Vector3
func compute_cosmetic_tilt(acceleration_vector: Vector3) -> Vector3
```

### 6.5. `WeaponManager` (`res://scripts/weapons/weapon_manager.gd`)
```gdscript
class_name WeaponManager
extends Node

@export var weapon_slots: Array[WeaponData] = []
var current_slot_index: int = 0
var ammo_counts: Array[int] = []
var damage_multiplier: float = 1.0
var structure_damage_bonus: float = 0.0
var pierce_first_target: bool = false

func select_slot(slot_index: int) -> void
func cycle_next_slot() -> void
func try_fire(muzzle_transform: Transform3D, target_node: Node3D = null) -> bool
func replenish_ammo_fraction(fraction: float) -> void
func get_current_ammo() -> int
```

### 6.6. `BoonReceiverComponent` (`res://scripts/components/boon_receiver_component.gd`)
```gdscript
class_name BoonReceiverComponent
extends Node

var active_boons: Array[BoonData] = []
var auto_chaff_enabled: bool = false
var chaff_cooldown: float = 12.0

func apply_boon(boon: BoonData) -> void
func reset_boons() -> void
func try_trigger_chaff() -> bool
```

### 6.7. `EnemyAIController` (`res://scripts/components/enemy_ai_controller.gd`)
Controlador modular reutilizado pelos 5 arquétipos de inimigos regulares (`MercenarySquad`, `HunterDrone`, `PatrolBoat`, `LightTank_IFV`, `TurretSAM`), operando sobre os parâmetros de `EnemyStatsData`:
```gdscript
class_name EnemyAIController
extends Node

@export var stats: EnemyStatsData
@export var patrol_waypoints: Array[Vector3] = []

var current_waypoint_index: int = 0
var fire_cooldown_timer: float = 0.0

func compute_movement_velocity(current_pos: Vector3, target_pos: Vector3, delta: float) -> Vector3
func can_engage_target(current_pos: Vector3, target_pos: Vector3) -> bool
func is_suppressing_position(enemy_pos: Vector3, civilian_pos: Vector3) -> bool
```

---

## 7. Contratos dos Autoloads de Estado e Meta-Progressão (`res://scripts/globals/`)

### 7.1. `GameState` (`res://scripts/globals/game_state.gd`)
Gerencia o ciclo de vida da incursão atual (*Run State*).
```gdscript
extends Node

enum RunStatus { IDLE, IN_PROGRESS, PAUSED_BOON, VICTORY, FAILED }

var current_status: RunStatus = RunStatus.IDLE
var rescued_in_current_run: int = 0
var active_run_boons: Array[String] = []

func start_new_run() -> void
func register_extracted_civilians(count: int) -> void
func complete_run_victory() -> void
func fail_run(reason: String) -> void
```

### 7.2. `MetaProgression` (`res://scripts/globals/meta_progression.gd`)
Gerencia os *Personnel Tokens* (sobreviventes extraídos com sucesso ao Heliponto Aliado) e persiste os níveis de upgrade do Hangar em texto plano JSON (`user://meta_progression.json`).
```gdscript
extends Node

const SAVE_PATH: String = "user://meta_progression.json"

var personnel_tokens: int = 0
var upgrade_levels: Dictionary = {
    "expand_cabin": 0,
    "reinforce_armor": 0,
    "ammo_logistics": 0
}

func add_personnel_tokens(amount: int) -> void
func can_afford_upgrade(upgrade: HangarUpgradeData) -> bool
func purchase_upgrade(upgrade: HangarUpgradeData) -> bool
func get_upgrade_level(upgrade_id: String) -> int
func save_to_disk() -> void
func load_from_disk() -> void
```
