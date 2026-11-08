# AGENTS.md: Protocolo de Desenvolvimento Autônomo — Blackout Strike

## 1. Diretriz e Perfil Operacional
Você atua como Arquiteto de Software e Engenheiro de Jogos Sênior especialista em **Godot 4.x (Forward+ / Vulkan)** para Windows. Seu objetivo é implementar a arquitetura de **Blackout Strike** seguindo rigorosamente os paradigmas de **Spec-Driven Development (SDD)**, **Test-Driven Development (TDD)** e **Design Baseado em Componentes**.

---

## 2. Padrões de Código e Arquitetura

### 2.1. Formatos e Controle de Versão
- Todos os arquivos do projeto devem ser texto plano: `.tscn` (cenas), `.gd` (GDScript), `.gdshader` (shaders) e `.json` / `.tres` (tabelas de dados e recursos).
- Formatos binários proprietários opacos são proibidos.
- Todo script GDScript exige **tipagem estática forte**:
  ```gdscript
  # Correto
  var current_fuel: float = 100.0
  func take_damage(amount: float, source: Node3D) -> void:

  # Proibido (tipagem dinâmica/fraca)
  var current_fuel = 100.0
  func take_damage(amount, source):

### 2.2. Arquitetura de Sinais (Signal Bus & Hierarquia)
Downwards Calls, Upwards Signals: Nós pais acessam e chamam métodos diretos nos filhos. Nós filhos comunicam mudanças de estado exclusivamente através de sinais emitidos para cima (signal).

EventBus Autoload: Para desacoplar UI, áudio e telemetria do loop de física, eventos globais de ciclo de vida (ex: `EventBus.player_died`, `EventBus.civilian_extracted`, `EventBus.boon_applied`) passam por um nó Autoload centralizado.

### 2.3. Componentização Estrita
Entidades vivas não acumulam lógica monolítica no nó raiz. Use nós filhos especializados:

HealthComponent: Gerencia integridade da blindagem, resistências e disparo de explosão.

FuelComponent: Taxa de consumo passivo/ativo, verificação de pane seca e reabastecimento.

CargoComponent: Capacidade da cabine de resgate, contagem de passageiros e fluxo de embarque/desembarque.

WeaponManager: Slots de armas, contadores de munição e cálculo de dispersão balística.

BoonReceiverComponent: Aplica e recalcula os modificadores temporários (perks de run) nos componentes da aeronave.

### 3. Pipeline de Ciclo de Vida da Feature (SDD Cycle)
Cada tarefa descrita em `docs/09_TASKS.md` e especificada em `docs/03_SPEC.md` deve seguir a cadeia documental em `docs/` (`01_WORLD.md` a `09_TASKS.md`) e passar pelas 5 etapas ordenadas:

Plan: Ler o requisito em `docs/03_SPEC.md`, `docs/04_ARCHITECTURE.md` e `docs/05_DATA_SCHEMA.md`, declarando nós envolvidos, sinais e contratos de dados tipados.

Contract & Test Harness: Criar o script de teste isolado em `res://tests/unit/` ou `res://tests/integration/` conforme `docs/08_TESTS.md` (ex: `res://tests/unit/test_fuel_component.gd`) com asserções numéricas no framework GUT que validem o comportamento matemático antes da arte/efeitos visuais.

Implement: Escrever a lógica em GDScript limpo, aplicando os componentes necessários e os shaders/ativos de `docs/06_SHADERS.md` e `docs/07_ASSETS.md`.

Integrate: Instanciar o nó no fluxo principal da fase ou registrar no EventBus.

Verify: Executar a asserção do teste e validar os Critérios de Aceitação da spec sem regressões.

## 4. Estrutura de Pastas do Repositório
```text
res://
├── AGENTS.md               # Protocolo operacional para agentes autônomos
├── README.md               # Visão geral e índice navegável da cadeia SDD
├── docs/                   # Cadeia sequencial de especificações SDD (01 a 09)
│   ├── 01_WORLD.md         # Universo narrativo e direção de arte
│   ├── 02_STORYLINE.md     # Bíblia de história, atos e transmissões de rádio
│   ├── 03_SPEC.md          # Especificação funcional e matemática do MVP
│   ├── 04_ARCHITECTURE.md  # Árvore de cenas, camadas de física e contratos de código
│   ├── 05_DATA_SCHEMA.md   # Schemas de CustomResource (.gd/.tres) e balanceamento
│   ├── 06_SHADERS.md       # Shaders espaciais em GDShader (oceano, anel, rotor wash)
│   ├── 07_ASSETS.md        # Manifesto CC0, áudio, WorldEnvironment e placeholders
│   ├── 08_TESTS.md         # Protocolo TDD e suítes do framework GUT
│   └── 09_TASKS.md         # Fila de tarefas atômicas por Sprint
├── assets/
│   ├── audio/              # SFX (turbinas, armas, sirenes) e trilhas
│   ├── models/             # Malhas .glb/.gltf (boss, characters, military, vehicles)
│   ├── shaders/            # Shaders .gdshader (água, dispersão, anel de resgate)
│   └── textures/           # PBR maps (albedo, roughness, metallic, emissive)
├── scenes/
│   ├── core/               # MainLoop, Câmera Ortográfica, EventBus
│   ├── entities/
│   │   ├── player/         # R-9X Mohawk III, malhas, colisores e subsistemas
│   │   ├── enemies/        # Torretas, infantaria, lanchas patrulha, Boss
│   │   └── npcs/           # Cientistas, engenheiros e abrigos destrutíveis
│   ├── environment/        # Terreno da ilha, malha do mar, helipontos
│   ├── roguelite/          # Telas de seleção de boons, crates de drop, tela de hangar
│   ├── ui/                 # HUD retrô-moderno, tacômetro, indicadores
│   └── vfx/                # Partículas GPU de explosão, fumaça, rotor wash
├── scripts/
│   ├── components/         # HealthComponent, FuelComponent, CargoComponent, FlightMovementController, BoonReceiverComponent
│   ├── data/               # Scripts de schema e recursos .tres (tabelas de armas, upgrades de hangar, catálogo de boons)
│   ├── globals/            # event_bus.gd, game_state.gd, meta_progression.gd
│   ├── procedural/         # spawn_director.gd (distribuição semi-procedural)
│   └── weapons/            # weapon_manager.gd, projectile.gd, mísseis guiados, canhão Vulcan
├── tests/
│   ├── unit/               # Testes unitários isolados de componentes e matemática (GUT)
│   └── integration/        # Testes de integração de entidades, física e fases do Boss (GUT)
└── scratch/                # Ambiente volátil para experimentos e artefatos temporários
```
