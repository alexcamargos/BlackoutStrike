# Blackout Strike: Visão Geral e Cadeia SDD do Projeto

**Blackout Strike** é um jogo de ação tática e resgate em 2.5D desenvolvido em **Godot 4.x (Forward+/Vulkan)** para Windows, que reimagina clássicos dos anos 90 como *Urban Strike* e *Choplifter* sob a estética saturada e o acabamento técnico de títulos modernos como *Sky Force Anniversary/Reloaded*. O jogador pilota o helicóptero de combate *R-9X Mohawk III* através de um arquipélago tropical com câmera oblíqua, combinando física de voo inercial, gerenciamento tenso de recursos (blindagem, combustível e três categorias de armamento balístico e guiado) e o resgate aéreo de sobreviventes no solo via anel holográfico de embarque.

A narrativa acompanha o Major Nathan Cross contra a *Aetheris*, conglomerado de infraestrutura digital e IA liderado pelo magnata Julian Vane, que orquestrou um blecaute físico e cibernético global para forçar a capitulação das democracias mundiais. Integrando mecânicas modernas de **roguelite**, cada incursão (*run*) possui disposição semi-procedural de abrigos e defesas inimigas, oferecendo escolhas de modificadores táticos temporários (*boons*) ao destruir depósitos de dados. O resgate de especialistas civis alimenta a meta-progressão permanente no hangar do porta-aviões aliado, desbloqueando melhorias estruturais de fuselagem, autonomia e capacidade de cabine.

Tecnicamente, o projeto adota o fluxo de **Desenvolvimento Dirigido por Especificações (SDD)** com testes automatizados via **GUT (Godot Unit Testing)**. A base de código é 100% estruturada em GDScript com tipagem estática e desacoplada por componentes reutilizáveis (`HealthComponent`, `FuelComponent`, `CargoComponent`, `WeaponManager`, `FlightMovementController`, `BoonReceiverComponent`) que se comunicam através de um barramento global de eventos (`EventBus`).

---

## Cadeia Lógica de Documentação (Fluxo SDD)

O repositório organiza suas especificações em `docs/` seguindo uma sequência numerada que espelha o ciclo de engenharia: da concepção do universo e regras matemáticas até a arquitetura de nós, shaders, suítes de testes e fila de execução por Sprints.

| Ordem | Documento | Etapa na Cadeia SDD | Função Principal |
| :---: | :--- | :--- | :--- |
| **00** | [`AGENTS.md`](AGENTS.md) | **Protocolo Operacional** | Regras de código, tipagem estática, padrão de sinais, ciclo de 5 etapas do SDD e árvore de diretórios. |
| **01** | [`docs/01_WORLD.md`](docs/01_WORLD.md) | **Domínio & Direção Visual** | Premissa de mundo, justificativa diegética do loop roguelite e direção de arte estilo *Sky Force*. |
| **02** | [`docs/02_STORYLINE.md`](docs/02_STORYLINE.md) | **Bíblia Narrativa** | Pilares temáticos, perfil dos personagens, campanha em 4 Atos e sistema de transmissão de rádio. |
| **03** | [`docs/03_SPEC.md`](docs/03_SPEC.md) | **Especificação Funcional** | Parâmetros matemáticos de voo, armas, resgate, inimigos, fases do chefe *Apex Bastion* e critérios de aceite. |
| **04** | [`docs/04_ARCHITECTURE.md`](docs/04_ARCHITECTURE.md) | **Arquitetura & Contratos** | Camadas de colisão 3D, hierarquia de cenas, contratos públicos de componentes, Autoloads e `EventBus`. |
| **05** | [`docs/05_DATA_SCHEMA.md`](docs/05_DATA_SCHEMA.md) | **Modelagem de Dados** | Classes `CustomResource` (`.gd`) e tabela de balanceamento base serializada em `.tres`. |
| **06** | [`docs/06_SHADERS.md`](docs/06_SHADERS.md) | **Pipeline Gráfico** | Código GLSL (`.gdshader`) do oceano com profundidade/espuma, anel holográfico de resgate e *rotor wash*. |
| **07** | [`docs/07_ASSETS.md`](docs/07_ASSETS.md) | **Ativos, Áudio & Ambiente** | Manifesto de pacotes CC0, limites PBR, buses de áudio, `WorldEnvironment` e política de *placeholders*. |
| **08** | [`docs/08_TESTS.md`](docs/08_TESTS.md) | **Validação TDD (GUT)** | Comando de execução headless, suítes de testes unitários/integração e matriz de cobertura obrigatória. |
| **09** | [`docs/09_TASKS.md`](docs/09_TASKS.md) | **Backlog de Execução** | Fila sequencial de tarefas atômicas divididas em 5 Sprints com dependências e critérios verificáveis. |
