# 08_TESTS.md: Protocolo de Testes Unitários e Integração (TDD)

## 1. Ferramenta de Testes
O projeto utiliza o framework **GUT (Godot Unit Testing)** para execução automatizada de suítes de teste.

### Execução via Linha de Comando (Modo Headless)
Os agentes devem validar suas implementações rodando:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
Nenhum código de feature deve ser considerado concluído caso os testes apresentem falhas (*exit code != 0*).

### Execução de aceitação visual (GPU Vulkan)

O GUT headless não certifica aparência. A aceitação visual requer executor Windows
com GPU Vulkan, fixture e captura determinística para cada VC-01 a VC-08 de
`10_VISUAL_CONTRACT.md`. O pipeline deve validar o manifesto, rejeitar primitivas
visíveis em `scenes/`, comparar imagem com SSIM >= 0,97 fora das máscaras permitidas
e medir a rota de 120 s do perfil de desempenho. Enquanto o manifesto estiver
`BLOCKED_BY_REFERENCE_APPROVAL`, a etapa visual deve reportar bloqueio, e não êxito.

---

## 2. Casos de Teste Essenciais para o MVP

### 2.1. Testes de Combustível (`res://tests/unit/test_fuel_component.gd`)
```gdscript
extends GutTest

var fuel_component: FuelComponent

func before_each() -> void:
    fuel_component = FuelComponent.new()
    fuel_component.max_fuel = 100.0
    fuel_component.current_fuel = 100.0
    fuel_component.passive_burn_rate = 1.0
    fuel_component.active_burn_rate = 2.0
    add_child_autofree(fuel_component)

func test_fuel_depletes_passively_over_time() -> void:
    fuel_component.consume_passive(1.0)
    assert_almost_eq(fuel_component.current_fuel, 99.0, 0.01, "O combustível deve drenar passivamente.")

func test_fuel_triggers_signal_on_empty() -> void:
    watch_signals(fuel_component)
    fuel_component.consume_active(50.0) # Reduz 100 unidades a 2.0 u/s
    assert_signal_emitted(fuel_component, "fuel_depleted", "O sinal de pane seca deve ser emitido quando atingir zero.")
    assert_eq(fuel_component.current_fuel, 0.0, "O combustível não deve admitir valores negativos.")
```

### 2.2. Testes de Blindagem e Vida (`res://tests/unit/test_health_component.gd`)
```gdscript
extends GutTest

var health: HealthComponent

func before_each() -> void:
    health = HealthComponent.new()
    health.max_health = 1000.0
    health.current_health = 1000.0
    add_child_autofree(health)

func test_damage_clamps_at_zero_and_emits_destroyed() -> void:
    watch_signals(health)
    health.take_damage(1200.0)
    assert_eq(health.current_health, 0.0, "A vida não deve ficar abaixo de zero.")
    assert_signal_emitted(health, "entity_destroyed", "Deve emitir entity_destroyed ao zerar HP.")

func test_repair_does_not_exceed_max_health() -> void:
    health.take_damage(200.0)
    health.repair(500.0)
    assert_eq(health.current_health, 1000.0, "O reparo não pode ultrapassar o teto de max_health.")
```

### 2.3. Testes de Lotação e Embarque de Carga (`res://tests/unit/test_cargo_component.gd`)
```gdscript
extends GutTest

var cargo: CargoComponent

func before_each() -> void:
    cargo = CargoComponent.new()
    cargo.max_capacity = 5
    add_child_autofree(cargo)

func test_cannot_board_past_max_capacity() -> void:
    for i in range(5):
        assert_true(cargo.try_board_passenger(), "Deve embarcar passageiro com espaço livre.")

    assert_false(cargo.try_board_passenger(), "Não deve permitir embarque se a cabine estiver lotada.")
    assert_eq(cargo.current_occupants, 5, "Lotação deve permanecer no valor máximo permitido.")

func test_unload_passengers_resets_cargo() -> void:
    cargo.current_occupants = 4
    var extracted_count: int = cargo.unload_all()
    assert_eq(extracted_count, 4, "Deve retornar a contagem correta de passageiros descarregados.")
    assert_eq(cargo.current_occupants, 0, "A cabine deve retornar a zero ocupantes após a descarga.")
```

### 2.4. Teste de Dano Estrutural e Exposição do Chefe (`res://tests/integration/test_boss_logic.gd`)
```gdscript
extends GutTest

var boss: BossApexBastion

func before_each() -> void:
    boss = load("res://scenes/entities/enemies/boss_apex_bastion.tscn").instantiate()
    add_child_autofree(boss)

func test_core_is_invulnerable_while_turrets_are_active() -> void:
    var initial_core_hp: float = boss.core_health.current_health
    boss.damage_core(100.0)
    assert_eq(boss.core_health.current_health, initial_core_hp, "O reator central não deve receber dano com as torretas intactas.")

func test_core_takes_damage_after_at_least_one_turret_falls() -> void:
    boss.bow_turret.health.take_damage(9999.0) # Destrói a torreta frontal
    boss.damage_core(100.0)
    assert_lt(boss.core_health.current_health, boss.core_health.max_health, "O reator deve ficar vulnerável após a queda da primeira torreta.")
```

---

## 3. Matriz de Cobertura de Testes Obrigatória

| Módulo | Tipo de Teste | Arquivo de Teste | Condição Crítica |
| :--- | :--- | :--- | :--- |
| `FuelComponent` | Unitário | `res://tests/unit/test_fuel_component.gd` | Drenagem passiva/ativa exata, bloqueio de valores negativos e emissão de `fuel_depleted`. |
| `HealthComponent` | Unitário | `res://tests/unit/test_health_component.gd` | Respeito aos limites $[0, \text{max\_health}]$, flag `is_invulnerable` e sinal `entity_destroyed`. |
| `CargoComponent` | Unitário | `res://tests/unit/test_cargo_component.gd` | Bloqueio acima de `max_capacity`, emissão de `cabin_full` e reset em `unload_all()`. |
| `FlightMovementController` | Unitário / Física | `res://tests/unit/test_flight_inertia.gd` | A velocidade deve convergir a zero de forma gradual após a interrupção do input. |
| `WeaponManager` | Lógica / Limites | `res://tests/unit/test_weapon_ammo.gd` | Não disparar com munição zerada e respeitar intervalo mínimo de cadência. |
| `RescueSensorArea` | Detecção e Supressão | `res://tests/unit/test_rescue_area.gd` | Bloquear embarque se $Y > 1.2\text{ m}$ ou se houver inimigo terrestre suprimindo o perímetro ($\le 10.0\text{ m}$); validar morte de civil por dano explosivo colateral. |
| `EnemyAIController` | Comportamento Modular | `res://tests/unit/test_enemy_ai.gd` | Validar máquina de estados para os 4 padrões (`STATIC_TURRET`, `GROUND_PATROL`, `NAVAL_PATROL`, `AIR_INTERCEPTOR`) e raio de supressão. |
| `BoonReceiverComponent` | Modificadores | `res://tests/unit/test_boons_math.gd` | A aplicação de boons não pode causar divisões por zero ou valores de velocidade infinitos. |
| `BossApexBastion` | Integração | `res://tests/integration/test_boss_logic.gd` | Invulnerabilidade do núcleo com torretas ativas e transição da Fase 1 para Fase 2 em $49\%$ de HP. |
