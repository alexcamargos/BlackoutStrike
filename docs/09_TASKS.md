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

- [x] **TASK-020: Sistema Modular de Projéteis (`Projectile.gd`)**
  - **Dependência:** TASK-010.
  - **Arquivos:** `res://scripts/weapons/projectile.gd` e cenas base de tiro de canhão e foguete.
  - **Lógica:** `Area3D` com velocidade linear, tempo de vida útil e detecção de impacto via máscara de colisão.
  - **Critério de Aceite:** Projétil aplica dano ao chamar `take_damage()` no nó receptor e instancia efeito de impacto antes de se desalocar da memória (`queue_free()`).

- [x] **TASK-021: Gerenciador de Armas do Helicóptero (`WeaponManager.gd`)**
  - **Dependência:** TASK-020.
  - **Arquivos:** `res://scripts/weapons/weapon_manager.gd`, `res://tests/unit/test_weapon_ammo.gd`.
  - **Lógica:** Controle dos três slots: Canhão Vulcan (Slot 1), Foguetes Hydra (Slot 2) e Míssil Hellfire (Slot 3). Controle estrito de cadência e redução de munição no disparo.
  - **Critério de Aceite:** Impossibilidade de atirar sem munição em qualquer slot e emissão contínua de sinais de inventário para a interface (`test_weapon_ammo.gd` verde).

- [x] **TASK-022: Míssil Guiado Hellfire com Travamento de Cone**
  - **Dependência:** TASK-021.
  - **Lógica:** Varredura cônica frontal de $40^\circ$ para detecção do inimigo hostil mais próximo; curva de aproximação guiada em direção ao alvo.
  - **Critério de Aceite:** O míssil altera seu vetor de trajetória em direção ao alvo móvel ou segue reto caso não existam entidades na área.

- [x] **TASK-023: Interface de Usuário (HUD) e Caixa de Rádio Militar**
  - **Dependência:** TASK-010, TASK-011, TASK-012, TASK-021.
  - **Arquivos:** `res://scenes/ui/hud.tscn`, `res://scenes/ui/radio_transmission_box.tscn`.
  - **Lógica:** Barras de Armor, Fuel, contadores dos 3 slots de armas, alerta *CABIN FULL*, tacômetro de sobreviventes a bordo e caixa de diálogo estilo *radio chatter* acionada via `EventBus.radio_transmission_requested`.
  - **Critério de Aceite:** HUD e caixa de rádio conectados puramente a sinais do `EventBus`, sem acoplamento a ponteiros diretos da entidade do helicóptero.

---

## Sprint 3: Resgate, Abrigos e Extração

- [x] **TASK-030: Estrutura Destrutível e Sobreviventes com Vulnerabilidade a Fogo Cruzado**
  - **Dependência:** TASK-012.
  - **Arquivos:** `res://scenes/entities/npcs/rescue_shelter.tscn`, `res://scenes/entities/npcs/civilian.tscn`.
  - **Lógica:** Edifício protegido com vida própria ($300.0\text{ HP}$ via `ShelterData`); ao ser destruído, emite `EventBus.shelter_destroyed` e gera no solo 4 instâncias de `Civilian` em raio de $2.5\text{ m}$. Cada civil possui `HealthComponent` ($30.0\text{ HP}$) vulnerável a explosões em área (foguetes Hydra/tanques) e fogo cruzado, emitindo `EventBus.civilian_killed` caso morra.
  - **Critério de Aceite:** Civis são liberados no solo com física estável e sofrem dano letal caso atingidos por raio explosivo.

- [x] **TASK-031: Componente de Carga, Anel Holográfico e Regra de Supressão de Perímetro**
  - **Dependência:** TASK-013, TASK-030.
  - **Arquivos:** `res://scripts/components/cargo_component.gd`, `res://assets/shaders/rescue_ring.gdshader`, `res://tests/unit/test_cargo_component.gd`, `res://tests/unit/test_rescue_area.gd`.
  - **Lógica:** Ao pairar em altitude $Y \le 1.2\text{ m}$ sobre o civil, projeta o disco holográfico. Se houver inimigos terrestres vivos em raio $\le 10.0\text{ m}$, o anel entra em estado `is_suppressed = true` (cor vermelho-alerta e progresso congelado). Sem supressão, preenche de $0^\circ$ a $360^\circ$ em $2.0\text{ s}$ e embarca 1 passageiro até o limite de 5.
  - **Critério de Aceite:** Supressão congela o embarque; subir acima de $Y > 1.2\text{ m}$ reseta o progresso; atingir 5 passageiros emite alerta e impede novos embarques (`test_cargo_component.gd` e `test_rescue_area.gd` verdes).

- [x] **TASK-032: Heliponto Aliado de Desembarque, Manutenção e Suprimentos de Campo**
  - **Dependência:** TASK-011, TASK-012, TASK-031.
  - **Arquivos:** `res://scenes/environment/ally_helipad.tscn`, `res://scenes/roguelite/supply_pickup.tscn`.
  - **Lógica:** `Area3D` do heliponto que detecta pouso ($Y \le 1.2\text{ m}$), descarrega passageiros incrementando `MetaProgression.personnel_tokens`, reabastece combustível ($15\text{ u/s}$) e conserta blindagem ($40\text{ HP/s}$); implementação de `AmmoCrate` ($+25\%$ munição) e `FuelDrum` ($+30.0$ combustível).
  - **Critério de Aceite:** Descarga bem-sucedida esvazia a capacidade do `CargoComponent` e computa moedas de meta-progressão.

---

## Sprint 4: Loop Roguelite, Boons, Hangar e Spawn Semi-Procedural

- [x] **TASK-040: Schemas de Dados e Catálogo de Recursos (`.tres`)**
  - **Dependência:** TASK-010.
  - **Arquivos:** `res://scripts/data/weapon_data.gd`, `res://scripts/data/boon_data.gd`, `res://scripts/data/hangar_upgrade_data.gd`, `res://scripts/data/helicopter_specs_data.gd`, `res://scripts/data/enemy_stats_data.gd`, `res://scripts/data/shelter_data.gd` e arquivos `.tres` correspondentes.
  - **Lógica:** Implementação integral dos schemas definidos em `docs/05_DATA_SCHEMA.md` e criação dos 5 Boons táticos do MVP, 3 armas, 3 upgrades de hangar e tabelas de inimigos/abrigos.
  - **Critério de Aceite:** Todos os recursos `.tres` são carregados via `ResourceLoader.load()` sem erros de sintaxe ou perda de tipagem.

- [x] **TASK-041: Receptor de Boons (`BoonReceiverComponent.gd`) e Menu Modal de Seleção**
  - **Dependência:** TASK-040.
  - **Arquivos:** `res://scripts/components/boon_receiver_component.gd`, `res://scenes/roguelite/boon_selection_ui.tscn`, `res://scenes/roguelite/data_crate.tscn`, `res://tests/unit/test_boons_math.gd`.
  - **Lógica:** Ao destruir um `DataCrate` ($150.0\text{ HP}$), pausa a árvore de cena, exibe 3 cartas de `BoonData` sorteadas e aplica o modificador escolhido aos componentes do helicóptero via `BoonReceiverComponent`.
  - **Critério de Aceite:** A escolha selecionada atualiza imediatamente as variáveis da entidade sem gerar divisões por zero (`test_boons_math.gd` verde) e retoma a execução normal do jogo.

- [x] **TASK-042: Diretor de Instanciação Híbrida e Ondas Reativas (`SpawnDirector.gd`)**
  - **Dependência:** TASK-030, TASK-032, TASK-041.
  - **Arquivo:** `res://scripts/procedural/spawn_director.gd`.
  - **Lógica:** No início da run, sorteia coordenadas pré-marcadas na ilha fixa para posicionar 3 abrigos + 3 `MercenarySquad` (entre 6 pontos), 4 `TurretSAM` (entre 8 pontos), 2 `LightTank_IFV`, 2 `PatrolBoat` e 2 `DataCrate` (entre 4 pontos). Escuta `EventBus.shelter_destroyed` e `EventBus.data_crate_opened` para disparar ondas reativas (*The Reactive Grid*: 2 `HunterDrone` aéreos + 1 `MercenarySquad` terrestre).
  - **Critério de Aceite:** Alocação inicial sem sobreposição e disparo imediato de reforços ao destruir abrigos ou crates de dados.

- [x] **TASK-043: Tela de Hangar e Aplicação da Meta-Progressão Permanente**
  - **Dependência:** TASK-032, TASK-040.
  - **Arquivo:** `res://scenes/roguelite/hangar_screen.tscn`.
  - **Lógica:** Interface conectada ao `MetaProgression.gd` permitindo gastar *Personnel Tokens* nos 3 upgrades permanentes (`expand_cabin`, `reinforce_armor`, `ammo_logistics`) e aplicar os bônus no início de cada nova incursão.
  - **Critério de Aceite:** Compra de upgrade deduz tokens, incrementa o nível salvo em `user://meta_progression.json` e inicializa o `PlayerHelicopter` com os novos tetos de capacidade.

---

## Sprint 5: Inimigos, Chefe Modular e Pipeline Visual

- [x] **TASK-050: Controlador Modular de IA (`EnemyAIController.gd`) e os 5 Arquétipos Hostis**
  - **Dependência:** TASK-012, TASK-020, TASK-040.
  - **Arquivos:** `res://scripts/components/enemy_ai_controller.gd`, `res://scenes/entities/enemies/mercenary_squad.tscn`, `res://scenes/entities/enemies/hunter_drone.tscn`, `res://scenes/entities/enemies/patrol_boat.tscn`, `res://scenes/entities/enemies/light_tank_ifv.tscn`, `res://scenes/entities/enemies/turret_sam.tscn`, `res://tests/unit/test_enemy_ai.gd`.
  - **Lógica:** Implementação do controlador parametrizado por `EnemyStatsData.BehaviorType` (`STATIC_TURRET`, `GROUND_PATROL`, `NAVAL_PATROL`, `AIR_INTERCEPTOR`), verificação de supressão de resgate ($\le 10.0\text{ m}$) e instanciação dos 5 inimigos regulares da Missão 1.
  - **Critério de Aceite:** Todos os 5 arquétipos operam seus padrões de movimento/disparo, aplicam supressão quando configurados (`test_enemy_ai.gd` verde) e sorteiam drop de suprimentos ($35\%$) ao serem destruídos.

- [x] **TASK-051: Chefe da Missão: Canhoneiro Litorâneo *Apex Bastion***
  - **Dependências:** TASK-012, TASK-020, TASK-050.
  - **Arquivos:** `res://scenes/entities/enemies/boss_apex_bastion.tscn`, `res://tests/integration/test_boss_logic.gd`.
  - **Lógica:** Entidade com 3 módulos de colisão e vida distintos: Torreta Dupla de Proa ($800\text{ HP}$), Torreta Quádrupla de Popa ($800\text{ HP}$) e Núcleo Central de Comando ($2400\text{ HP}$). Implementação das Fases 1 (canhão 76mm + minas navais) e 2 (CIWS em leque + salva de 4 mísseis teleguiados).
  - **Critério de Aceite:** O núcleo só recebe dano após a queda de ao menos uma das torretas (`test_boss_logic.gd` verde); ao zerar o núcleo, executa sequência de destruição e emite `EventBus.boss_defeated` e `EventBus.mission_accomplished`.

- [x] **TASK-052: Shaders de Oceano, Rotor Wash, Câmera Tática e Ambiente Estilo Sky Force**
  - **Dependência:** TASK-013.
  - **Arquivos:** `res://assets/shaders/ocean_pbr.gdshader`, `res://assets/shaders/rotor_wash.gdshader`, `res://scenes/core/world_environment.tres`, `res://scenes/core/tactical_camera.tscn`, `res://scenes/core/mission_01_midway.tscn`.
  - **Lógica:** Integração da cena principal da Missão 1 com câmera oblíqua ($68^\circ$, $FOV = 36^\circ$), shader de água com profundidade e espuma, decalque de `rotor_wash` sob o helicóptero e configuração de `WorldEnvironment` com Bloom Filmic e SSAO.
  - **Critério de Aceite:** A cena principal `mission_01_midway.tscn` carrega sem erros ou artefatos visuais no modo Forward+ e todas as suítes do GUT passam com código de saída `0`.


---

## Sprint 6: Superfícies PBR, Shaders e Cenário Litorâneo

- [ ] **TASK-060: Normal Maps Procedurais e Ativação Plena do Oceano PBR**
  - **Dependência:** TASK-052.
  - **Arquivos:** `res://assets/textures/water/ocean_wave_normal_1.tres`, `res://assets/textures/water/ocean_wave_normal_2.tres`, `res://scenes/core/mission_01_midway.tscn`.
  - **Lógica:** Gerar e vincular duas texturas de normais contínuas cruzadas aos uniforms `wave_normal_1` e `wave_normal_2` do material em `ocean_pbr.gdshader`. Calibrar a atenuação ótica pela profundidade (Beer-Lambert de turquesa raso `#14A6B8` a azul-marinho abissal `#031438`) e afinar a faixa de espuma de intersecção (`foam_intersection_depth = 0.45`).
  - **Critério de Aceite:** O oceano exibe micro-reflexos especulares solares dinâmicos em movimento contínuo e gera bordas de espuma suave no contato com a terra; testes automatizados continuam passando sem erros.

- [ ] **TASK-061: Terreno Litorâneo Modular e Topografia da Ilha Midway**
  - **Dependência:** TASK-042, TASK-060.
  - **Arquivos:** `res://scenes/environment/island_terrain_midway.tscn`, `res://scenes/core/mission_01_midway.tscn`.
  - **Lógica:** Substituir o bloco cúbico de areia por malha de relevo costeiro dividida em 3 cotas: faixa de praia rasa com declive suave ($Y \in [-0.2, 0.3]\text{ m}$), falésias rochosas com sombras nítidas ($Y \in [0.5, 6.0]\text{ m}$) e platôs industriais planos ($Y = 0.5\text{ m}$). Preservar a camada de física estática (`collision_layer = 1`) e os marcadores de posição do `SpawnDirector`.
  - **Critério de Aceite:** Aeronave em voo rasante e projéteis colidem normalmente com o terreno; civis e tanques mantêm navegação terrestre estável; `test_spawn_director.gd` e `test_rescue_area.gd` passam sem regressão.

- [ ] **TASK-062: Decoração de Cenário e Escala com MultiMeshInstance3D**
  - **Dependência:** TASK-061.
  - **Arquivos:** `res://scenes/environment/island_props.tscn`, `res://scenes/core/mission_01_midway.tscn`.
  - **Lógica:** Implementar instanciamento em lote via `MultiMeshInstance3D` para vegetação litorânea (palmeiras estilizadas), contêineres marítimos da Aetheris e guindastes portuários, estabelecendo contraste de escala entre a ilha e a aeronave sem adicionar sobrecarga de draw calls na GPU.
  - **Critério de Aceite:** Adição de elementos de ambientação sem interferir na malha de navegação terrestre nem nos volumes de colisão de resgate.

---

## Sprint 7: Modelos 3D de Entidades, Malhas Modulares e Animações

- [ ] **TASK-070: Modelo PBR e Articulação do R-9X Mohawk III**
  - **Dependência:** TASK-013, TASK-052.
  - **Arquivos:** `res://scenes/entities/player/player_helicopter.tscn`, `res://assets/models/vehicles/r9x_mohawk.glb`.
  - **Lógica:** Substituir os cubos de fuselagem por modelo 3D dedicado de helicóptero militar. Aplicar material PBR padrão JTF Vanguard: pintura azul-chumbo (`#2A3847`), metalicidade $0.8$, rugosidade $0.25$ e canopy escurecido reflexivo. Separar e articular o rotor principal e de cauda com rotação contínua e blur estético, preservando os marcadores `MuzzleMarkers` e os nós de subsistema intactos.
  - **Critério de Aceite:** A suíte `test_flight_inertia.gd` passa integralmente; rotações de yaw e inclinação cosmética de até $22^\circ$ funcionam sem desalinhamento das armas.

- [ ] **TASK-071: Modelos Modulares dos 5 Arquétipos Inimigos (Aetheris)**
  - **Dependência:** TASK-050.
  - **Arquivos:** `res://scenes/entities/enemies/mercenary_squad.tscn`, `res://scenes/entities/enemies/hunter_drone.tscn`, `res://scenes/entities/enemies/patrol_boat.tscn`, `res://scenes/entities/enemies/light_tank_ifv.tscn`, `res://scenes/entities/enemies/turret_sam.tscn`.
  - **Lógica:** Importar e configurar malhas dos pacotes CC0 (*Kenney Military Kit* e *Vehicle Kit*) aplicando a paleta antracite (`#1F2226`) com óticas e miras laser emissivas em vermelho-alaranjado (`#D9381E`) em HDR. Manter nós móveis de torreta desacoplados para apontamento angular em direção ao alvo.
  - **Critério de Aceite:** `test_enemy_ai.gd` passa com todos os 5 arquétipos operacionais; rotação visual das armas coincide com o vetor de disparo dos projéteis.

- [ ] **TASK-072: Modelo Modular de Guerra Naval: Chefe Apex Bastion**
  - **Dependência:** TASK-051.
  - **Arquivos:** `res://scenes/entities/enemies/boss_apex_bastion.tscn`.
  - **Lógica:** Substituir os blocos do chefe por modelo naval detalhado com separação em nós de topo: casco principal com linhas de flutuação, Torreta de Proa (canhão 76mm móvel), Torreta de Popa (CIWS quádruplo) e Núcleo Central de Comando com blindagem retrátil e pulso emissivo ativado na Fase 2.
  - **Critério de Aceite:** Suíte `test_boss_logic.gd` passa 100% verde; destruição de cada módulo desativa a torreta correspondente e altera o material para malha avariada/enfumaçada.

- [ ] **TASK-073: Malhas de Civis, Cientistas e Abrigos Destrutíveis**
  - **Dependência:** TASK-030.
  - **Arquivos:** `res://scenes/entities/npcs/civilian.tscn`, `res://scenes/entities/npcs/rescue_shelter.tscn`.
  - **Lógica:** Integrar modelos de cientistas e engenheiros (Kay Lousberg CC0) com uniformes de alta visibilidade contrastante. Implementar abrigo com textura de concreto reforçado e gerar peças fragmentadas de escombros instanciadas na destruição do edifício.
  - **Critério de Aceite:** Civis são liberados no solo no raio de $2.5\text{ m}$ sem colisões anômalas; suítes `test_rescue_shelter.gd` e `test_rescue_area.gd` verdes.

---

## Sprint 8: Efeitos Visuais (VFX GPU), Balística Emissiva e Feedback de Combate

- [ ] **TASK-080: Balística Hiper-Visível e Traçantes Emissivos de Canhões e Mísseis**
  - **Dependência:** TASK-020, TASK-022.
  - **Arquivos:** `res://scenes/weapons/projectile_vulcan.tscn`, `res://scenes/weapons/projectile_hydra.tscn`, `res://scenes/weapons/projectile_hellfire.tscn`, `res://scenes/weapons/projectile_enemy_*.tscn`.
  - **Lógica:** Configurar tiros do Vulcan como cápsulas alongadas traçantes com emissão amarela intensa (energia $\ge 4.0$). Adicionar nó `GPUParticles3D` nos foguetes Hydra e mísseis Hellfire com emissão de pluma de fumaça cinza e fagulhas incandescentes na esteira. Projéteis hostis estilizados em plasma carmesim/laranja com Bloom destacado.
  - **Critério de Aceite:** Projéteis claramente legíveis contra o mar e solo; `test_projectile.gd` e `test_homing_missile.gd` passam sem alterações.

- [ ] **TASK-081: Sistemas de Partículas GPU de Impacto, Explosão e Destroços**
  - **Dependência:** TASK-020, TASK-080.
  - **Arquivos:** `res://scenes/vfx/impact_effect.tscn`, `res://scenes/vfx/explosion_heavy.tscn`, `res://scenes/vfx/water_splash.tscn`.
  - **Lógica:** Implementar sistema de impacto discriminado por superfície: faíscas metálicas em blindagens, impacto de poeira no solo e borrifos verticais (`water_splash`) no mar. Criar prefab de explosão pesada em duas etapas para veículos e estruturas destruídas (clarão pontual, bola de fogo volumétrica expansiva e fragmentos com física simples de gravidade).
  - **Critério de Aceite:** Efeitos possuem ciclo de vida finito com desalocação automática da memória (`one_shot = true` e limpeza de nós sem vazamentos).

- [ ] **TASK-082: Refinamento do Rotor Wash e Anel de Resgate Holográfico**
  - **Dependência:** TASK-031, TASK-052.
  - **Arquivos:** `res://assets/shaders/rescue_ring.gdshader`, `res://assets/shaders/rotor_wash.gdshader`, `res://scenes/entities/player/player_helicopter.tscn`.
  - **Lógica:** Modular a intensidade do `rotor_wash.gdshader` dinamicamente conforme a altitude do R-9X ($Y \le 1.8\text{ m}$ projeta anel de ondas visível na água; altitudes maiores desvanecem o decalque). Calibrar emissão HDR do anel de resgate ($2.5$) para contraste sobre areia e asfalto, com transição de cor para carmesim pulsante em $14\text{ rad/s}$ quando suprimido.
  - **Critério de Aceite:** `test_rescue_area.gd` passa sem erros; resposta visual imediata na presença de inimigos a menos de $10\text{ m}$.

---

## Sprint 9: Iluminação Tropical, Atmosfera e Interface Retrô-Moderna

- [ ] **TASK-090: Calibração de Luz Solar, Sombras em Cascata e Atmosfera Oceânica**
  - **Dependência:** TASK-052, TASK-060.
  - **Arquivos:** `res://scenes/core/world_environment.tres`, `res://scenes/core/mission_01_midway.tscn`.
  - **Lógica:** Configurar a `DirectionalLight3D` com ângulo rasante quente ($55^\circ$ elevação, $-40^\circ$ azimute, cor `#FFF0D9`), sombras direcionais PSSM 4 Splits com distância máxima de corte calibrada para $180\text{ m}$. Ajustar névoa de distância volumétrica no `WorldEnvironment` iniciando a $120\text{ m}$ com coloração azul-profundo (`#122233`) para suavizar o horizonte oceânico.
  - **Critério de Aceite:** Fuselagens metálicas geram brilhos especulares intensos durante as curvas e rolagens; contraste profundo e nítido das sombras sobre as praias e mar.

- [ ] **TASK-091: Estilização do HUD Militar e Efeitos Diegéticos na Caixa de Rádio**
  - **Dependência:** TASK-023.
  - **Arquivos:** `res://scenes/ui/hud.tscn`, `res://scenes/ui/radio_transmission_box.tscn`, `res://assets/textures/ui/`.
  - **Lógica:** Aplicar tema visual unificado militar com recortes em $45^\circ$, barras angulares segmentadas de blindagem e combustível, indicadores de contagem de passageiros e retícula de mira com feedback de travamento de alvos. Adicionar camada de scanlines analógicas e estática nos retratos de comunicação de Nathan Cross e Julian Vane.
  - **Critério de Aceite:** Suíte `test_hud_and_radio.gd` 100% verde; interface adaptável e legível em resolução 1080p sem corte de informações.

- [ ] **TASK-092: Integração de Áudio Espacial e Bus de Efeitos Acústicos**
  - **Dependência:** TASK-010, TASK-070, TASK-080.
  - **Arquivos:** `res://default_bus_layout.tres`, nós `AudioStreamPlayer3D` no helicóptero, armas e inimigos.
  - **Lógica:** Conectar arquivos sonoros CC0 (`sfx_helo_loop.ogg`, `sfx_vulcan_shot.wav`, `sfx_rocket_launch.wav`) aos buses de áudio configurados (`SFX_Player`, `SFX_Weapons`, `SFX_Combat`, `UI_Alarms`). Aplicar modulação de pitch no rotor do helicóptero vinculada à velocidade linear ($0.95$ a $1.15$) e manter proteções de execução em modo headless para não quebrar a suíte de testes.
  - **Critério de Aceite:** Execução em `godot --headless` sem falhas de áudio; sons de combate atenuam realisticamente no espaço 3D; `test_base_configuration.gd` passa sem erros.
