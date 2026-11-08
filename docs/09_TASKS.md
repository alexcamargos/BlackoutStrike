# 09_TASKS.md: Fila de Tarefas Atômicas e Backlog de Execução

Este arquivo coordena as iterações de desenvolvimento para agentes autônomos. Cada tarefa é atômica, possui dependências explícitas e um critério de aceitação verificável por testes.

---

## Sprint 1: Fundação do Core, Eventos e Cinemática do Helicóptero

- [x] **TASK-010: Configuração Base do Repositório, InputMap, Áudio e Autoloads**
  - **Contexto:** Inicializar o projeto Godot 4.3+, configurar render Forward+, camadas de colisão 3D (1 a 8), `InputMap` (`move_north`, `move_south`, `move_west`, `move_east`, `altitude_descend`, `fire_primary`, `weapon_slot_1..3`, `weapon_cycle_next`), layout de áudio (`res://default_bus_layout.tres`) e nós globais.
  - **Entregáveis:** `res://scripts/globals/event_bus.gd`, `res://scripts/globals/game_state.gd`, `res://scripts/globals/meta_progression.gd` e `res://default_bus_layout.tres` registrados no `project.godot`.
  - **Critério de Aceite:** O projeto compila em modo headless (`godot --headless --quit`) sem erros de script e com os 3 singletons acessíveis globalmente.

- [x] **TASK-011: Componente de Combustível (`FuelComponent.gd`)**
  - **Dependência:** TASK-010.
  - **Arquivos:** `res://scripts/components/fuel_component.gd`, `res://tests/unit/test_fuel_component.gd`.
  - **Lógica:** Drenagem passiva ($0.7\text{ u/s}$), drenagem ativa em aceleração ($1.6\text{ u/s}$), emissão do sinal `fuel_changed(current, max_fuel)` e emissão de `fuel_depleted` quando $current \le 0.0$.
  - **Critério de Aceite:** Testes unitários validando transição para $0$ e bloqueio de valores negativos.

- [x] **TASK-012: Componente de Vida e Blindagem (`HealthComponent.gd`)**
  - **Dependência:** TASK-010.
  - **Arquivos:** `res://scripts/components/health_component.gd`, `res://tests/unit/test_health_component.gd`.
  - **Lógica:** Gestão de integridade ($1000\text{ HP}$ base), flag `is_invulnerable`, métodos `take_damage(amount, source)` e `repair(amount)`, emissão de `health_changed` e `entity_destroyed`.
  - **Critério de Aceite:** Dano reduz a vida de forma precisa e valores não ultrapassam o teto nem descem abaixo de zero.

- [x] **TASK-013: Controlador de Voo e Entidade do Helicóptero (`FlightMovementController.gd` & `PlayerHelicopter.gd`)**
  - **Dependências:** TASK-011, TASK-012.
  - **Arquivos:** `res://scripts/components/flight_movement_controller.gd`, `res://scenes/entities/player/player_helicopter.tscn`, `res://tests/unit/test_flight_inertia.gd`.
  - **Lógica:** `CharacterBody3D` orquestrando `FlightMovementController` com aceleração linear ($18.0\text{ m/s}^2$), velocidade máxima ($22.0\text{ m/s}$), arrasto inercial ($7.5\text{ m/s}^2$), transição entre cotas $Y = 4.0\text{ m}$ e $Y = 0.8\text{ m}$, rotação *Yaw* ($8.0\text{ rad/s}$), inclinação cosmética da malha até $22^\circ$ e sequência de autorrotação/queda em 3 segundos após `fuel_depleted`.
  - **Critério de Aceite:** Ao soltar o direcional na velocidade máxima, a aeronave percorre uma distância inercial mensurável antes de repousar completamente (`test_flight_inertia.gd` verde).

---

## Sprint 2: Balística, Armamentos e HUD Retrô-Moderno

- [ ] **TASK-020: Sistema Modular de Projéteis (`Projectile.gd`)**
  - **Dependência:** TASK-010.
  - **Arquivos:** `res://scripts/weapons/projectile.gd` e cenas base de tiro de canhão e foguete.
  - **Lógica:** `Area3D` com velocidade linear, tempo de vida útil e detecção de impacto via máscara de colisão.
  - **Critério de Aceite:** Projétil aplica dano ao chamar `take_damage()` no nó receptor e instancia efeito de impacto antes de se desalocar da memória (`queue_free()`).

- [ ] **TASK-021: Gerenciador de Armas do Helicóptero (`WeaponManager.gd`)**
  - **Dependência:** TASK-020.
  - **Arquivos:** `res://scripts/weapons/weapon_manager.gd`, `res://tests/unit/test_weapon_ammo.gd`.
  - **Lógica:** Controle dos três slots: Canhão Vulcan (Slot 1), Foguetes Hydra (Slot 2) e Míssil Hellfire (Slot 3). Controle estrito de cadência e redução de munição no disparo.
  - **Critério de Aceite:** Impossibilidade de atirar sem munição em qualquer slot e emissão contínua de sinais de inventário para a interface (`test_weapon_ammo.gd` verde).

- [ ] **TASK-022: Míssil Guiado Hellfire com Travamento de Cone**
  - **Dependência:** TASK-021.
  - **Lógica:** Varredura cônica frontal de $40^\circ$ para detecção do inimigo hostil mais próximo; curva de aproximação guiada em direção ao alvo.
  - **Critério de Aceite:** O míssil altera seu vetor de trajetória em direção ao alvo móvel ou segue reto caso não existam entidades na área.

- [ ] **TASK-023: Interface de Usuário (HUD) e Caixa de Rádio Militar**
  - **Dependência:** TASK-010, TASK-011, TASK-012, TASK-021.
  - **Arquivos:** `res://scenes/ui/hud.tscn`, `res://scenes/ui/radio_transmission_box.tscn`.
  - **Lógica:** Barras de Armor, Fuel, contadores dos 3 slots de armas, alerta *CABIN FULL*, tacômetro de sobreviventes a bordo e caixa de diálogo estilo *radio chatter* acionada via `EventBus.radio_transmission_requested`.
  - **Critério de Aceite:** HUD e caixa de rádio conectados puramente a sinais do `EventBus`, sem acoplamento a ponteiros diretos da entidade do helicóptero.

---

## Sprint 3: Resgate, Abrigos e Extração

- [ ] **TASK-030: Estrutura Destrutível e Sobreviventes com Vulnerabilidade a Fogo Cruzado**
  - **Dependência:** TASK-012.
  - **Arquivos:** `res://scenes/entities/npcs/rescue_shelter.tscn`, `res://scenes/entities/npcs/civilian.tscn`.
  - **Lógica:** Edifício protegido com vida própria ($300.0\text{ HP}$ via `ShelterData`); ao ser destruído, emite `EventBus.shelter_destroyed` e gera no solo 4 instâncias de `Civilian` em raio de $2.5\text{ m}$. Cada civil possui `HealthComponent` ($30.0\text{ HP}$) vulnerável a explosões em área (foguetes Hydra/tanques) e fogo cruzado, emitindo `EventBus.civilian_killed` caso morra.
  - **Critério de Aceite:** Civis são liberados no solo com física estável e sofrem dano letal caso atingidos por raio explosivo.

- [ ] **TASK-031: Componente de Carga, Anel Holográfico e Regra de Supressão de Perímetro**
  - **Dependência:** TASK-013, TASK-030.
  - **Arquivos:** `res://scripts/components/cargo_component.gd`, `res://assets/shaders/rescue_ring.gdshader`, `res://tests/unit/test_cargo_component.gd`, `res://tests/unit/test_rescue_area.gd`.
  - **Lógica:** Ao pairar em altitude $Y \le 1.2\text{ m}$ sobre o civil, projeta o disco holográfico. Se houver inimigos terrestres vivos em raio $\le 10.0\text{ m}$, o anel entra em estado `is_suppressed = true` (cor vermelho-alerta e progresso congelado). Sem supressão, preenche de $0^\circ$ a $360^\circ$ em $2.0\text{ s}$ e embarca 1 passageiro até o limite de 5.
  - **Critério de Aceite:** Supressão congela o embarque; subir acima de $Y > 1.2\text{ m}$ reseta o progresso; atingir 5 passageiros emite alerta e impede novos embarques (`test_cargo_component.gd` e `test_rescue_area.gd` verdes).

- [ ] **TASK-032: Heliponto Aliado de Desembarque, Manutenção e Suprimentos de Campo**
  - **Dependência:** TASK-011, TASK-012, TASK-031.
  - **Arquivos:** `res://scenes/environment/ally_helipad.tscn`, `res://scenes/roguelite/supply_pickup.tscn`.
  - **Lógica:** `Area3D` do heliponto que detecta pouso ($Y \le 1.2\text{ m}$), descarrega passageiros incrementando `MetaProgression.personnel_tokens`, reabastece combustível ($15\text{ u/s}$) e conserta blindagem ($40\text{ HP/s}$); implementação de `AmmoCrate` ($+25\%$ munição) e `FuelDrum` ($+30.0$ combustível).
  - **Critério de Aceite:** Descarga bem-sucedida esvazia a capacidade do `CargoComponent` e computa moedas de meta-progressão.

---

## Sprint 4: Loop Roguelite, Boons, Hangar e Spawn Semi-Procedural

- [ ] **TASK-040: Schemas de Dados e Catálogo de Recursos (`.tres`)**
  - **Dependência:** TASK-010.
  - **Arquivos:** `res://scripts/data/weapon_data.gd`, `res://scripts/data/boon_data.gd`, `res://scripts/data/hangar_upgrade_data.gd`, `res://scripts/data/helicopter_specs_data.gd`, `res://scripts/data/enemy_stats_data.gd`, `res://scripts/data/shelter_data.gd` e arquivos `.tres` correspondentes.
  - **Lógica:** Implementação integral dos schemas definidos em `docs/05_DATA_SCHEMA.md` e criação dos 5 Boons táticos do MVP, 3 armas, 3 upgrades de hangar e tabelas de inimigos/abrigos.
  - **Critério de Aceite:** Todos os recursos `.tres` são carregados via `ResourceLoader.load()` sem erros de sintaxe ou perda de tipagem.

- [ ] **TASK-041: Receptor de Boons (`BoonReceiverComponent.gd`) e Menu Modal de Seleção**
  - **Dependência:** TASK-040.
  - **Arquivos:** `res://scripts/components/boon_receiver_component.gd`, `res://scenes/roguelite/boon_selection_ui.tscn`, `res://scenes/roguelite/data_crate.tscn`, `res://tests/unit/test_boons_math.gd`.
  - **Lógica:** Ao destruir um `DataCrate` ($150.0\text{ HP}$), pausa a árvore de cena, exibe 3 cartas de `BoonData` sorteadas e aplica o modificador escolhido aos componentes do helicóptero via `BoonReceiverComponent`.
  - **Critério de Aceite:** A escolha selecionada atualiza imediatamente as variáveis da entidade sem gerar divisões por zero (`test_boons_math.gd` verde) e retoma a execução normal do jogo.

- [ ] **TASK-042: Diretor de Instanciação Híbrida e Ondas Reativas (`SpawnDirector.gd`)**
  - **Dependência:** TASK-030, TASK-032, TASK-041.
  - **Arquivo:** `res://scripts/procedural/spawn_director.gd`.
  - **Lógica:** No início da run, sorteia coordenadas pré-marcadas na ilha fixa para posicionar 3 abrigos + 3 `MercenarySquad` (entre 6 pontos), 4 `TurretSAM` (entre 8 pontos), 2 `LightTank_IFV`, 2 `PatrolBoat` e 2 `DataCrate` (entre 4 pontos). Escuta `EventBus.shelter_destroyed` e `EventBus.data_crate_opened` para disparar ondas reativas (*The Reactive Grid*: 2 `HunterDrone` aéreos + 1 `MercenarySquad` terrestre).
  - **Critério de Aceite:** Alocação inicial sem sobreposição e disparo imediato de reforços ao destruir abrigos ou crates de dados.

- [ ] **TASK-043: Tela de Hangar e Aplicação da Meta-Progressão Permanente**
  - **Dependência:** TASK-032, TASK-040.
  - **Arquivo:** `res://scenes/roguelite/hangar_screen.tscn`.
  - **Lógica:** Interface conectada ao `MetaProgression.gd` permitindo gastar *Personnel Tokens* nos 3 upgrades permanentes (`expand_cabin`, `reinforce_armor`, `ammo_logistics`) e aplicar os bônus no início de cada nova incursão.
  - **Critério de Aceite:** Compra de upgrade deduz tokens, incrementa o nível salvo em `user://meta_progression.json` e inicializa o `PlayerHelicopter` com os novos tetos de capacidade.

---

## Sprint 5: Inimigos, Chefe Modular e Pipeline Visual

- [ ] **TASK-050: Controlador Modular de IA (`EnemyAIController.gd`) e os 5 Arquétipos Hostis**
  - **Dependência:** TASK-012, TASK-020, TASK-040.
  - **Arquivos:** `res://scripts/components/enemy_ai_controller.gd`, `res://scenes/entities/enemies/mercenary_squad.tscn`, `res://scenes/entities/enemies/hunter_drone.tscn`, `res://scenes/entities/enemies/patrol_boat.tscn`, `res://scenes/entities/enemies/light_tank_ifv.tscn`, `res://scenes/entities/enemies/turret_sam.tscn`, `res://tests/unit/test_enemy_ai.gd`.
  - **Lógica:** Implementação do controlador parametrizado por `EnemyStatsData.BehaviorType` (`STATIC_TURRET`, `GROUND_PATROL`, `NAVAL_PATROL`, `AIR_INTERCEPTOR`), verificação de supressão de resgate ($\le 10.0\text{ m}$) e instanciação dos 5 inimigos regulares da Missão 1.
  - **Critério de Aceite:** Todos os 5 arquétipos operam seus padrões de movimento/disparo, aplicam supressão quando configurados (`test_enemy_ai.gd` verde) e sorteiam drop de suprimentos ($35\%$) ao serem destruídos.

- [ ] **TASK-051: Chefe da Missão: Canhoneiro Litorâneo *Apex Bastion***
  - **Dependências:** TASK-012, TASK-020, TASK-050.
  - **Arquivos:** `res://scenes/entities/enemies/boss_apex_bastion.tscn`, `res://tests/integration/test_boss_logic.gd`.
  - **Lógica:** Entidade com 3 módulos de colisão e vida distintos: Torreta Dupla de Proa ($800\text{ HP}$), Torreta Quádrupla de Popa ($800\text{ HP}$) e Núcleo Central de Comando ($2400\text{ HP}$). Implementação das Fases 1 (canhão 76mm + minas navais) e 2 (CIWS em leque + salva de 4 mísseis teleguiados).
  - **Critério de Aceite:** O núcleo só recebe dano após a queda de ao menos uma das torretas (`test_boss_logic.gd` verde); ao zerar o núcleo, executa sequência de destruição e emite `EventBus.boss_defeated` e `EventBus.mission_accomplished`.

- [ ] **TASK-052: Shaders de Oceano, Rotor Wash, Câmera Tática e Ambiente Estilo Sky Force**
  - **Dependência:** TASK-013.
  - **Arquivos:** `res://assets/shaders/ocean_pbr.gdshader`, `res://assets/shaders/rotor_wash.gdshader`, `res://scenes/core/world_environment.tres`, `res://scenes/core/tactical_camera.tscn`, `res://scenes/core/mission_01_midway.tscn`.
  - **Lógica:** Integração da cena principal da Missão 1 com câmera oblíqua ($68^\circ$, $FOV = 36^\circ$), shader de água com profundidade e espuma, decalque de `rotor_wash` sob o helicóptero e configuração de `WorldEnvironment` com Bloom Filmic e SSAO.
  - **Critério de Aceite:** A cena principal `mission_01_midway.tscn` carrega sem erros ou artefatos visuais no modo Forward+ e todas as suítes do GUT passam com código de saída `0`.
