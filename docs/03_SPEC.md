# 03_SPEC.md: Especificação Técnica do MVP — Blackout Strike

## 1. Visão Geral do MVP
Construir uma fatia vertical jogável para Windows baseada na primeira missão (*Atol de Midway*), combinando física inercial de helicóptero, resgate de sobreviventes em terraços e praias, combate contra forças mercenárias, ciclo de melhorias táticas de run (*boons*) e confronto final contra o canhoneiro litorâneo *Apex Bastion*.

---

## 2. Parâmetros da Aeronave do Jogador (`PlayerHelicopter`)

### 2.1. Controle e Cinemática
- **Tipo de Nó:** `CharacterBody3D`.
- **Altitude:** 
  - Altitude de Cruzeiro: $Y = 4.0$ m (padrão de navegação e combate).
  - Altitude de Resgate / Pouso: $Y = 0.8$ m (acionada ao segurar o botão de descida ou pairar em zonas de resgate).
- **Parâmetros de Movimento:**
  - Aceleração: $18.0\,m/s^2$.
  - Velocidade Máxima de Cruzeiro: $22.0\,m/s$.
  - Desaceleração Linear (Inércia / Arrasto): $7.5\,m/s^2$ (a aeronave desliza ao soltar o direcional).
  - Velocidade de Transição Vertical (Mudança de Altitude): $6.0\,m/s$.
  - Orientação Horizontal (*Yaw*): A proa gira suavemente (`yaw_turn_speed = 8.0 rad/s`) na direção do cursor do mouse projetado no plano horizontal de voo ($Y = 4.0\text{ m}$) ou, na ausência de movimento do cursor/uso de gamepad, alinha-se ao vetor de deslocamento ativo.
  - Inclinação Cosmética (*Pitch/Roll*): A malha 3D inclina dinamicamente até $22^\circ$ no vetor da aceleração atual (interpolação via `lerp` com peso $10.0 \times \delta$).
- **Mapeamento de Entradas (`InputMap` no `project.godot`):**
  - `move_north` (W / Seta Cima), `move_south` (S / Seta Baixo), `move_west` (A / Seta Esquerda), `move_east` (D / Seta Direita): Vetor direcional no plano XZ.
  - `altitude_descend` (Shift Esquerdo / Espaço / Botão Sul do Controle): Reduz a cota alvo de $Y = 4.0\text{ m}$ para $Y = 0.8\text{ m}$ enquanto pressionado.
  - `fire_primary` (Botão Esquerdo do Mouse / Gatilho Direito): Dispara a arma atualmente selecionada no `WeaponManager`.
  - `weapon_slot_1` (Tecla 1), `weapon_slot_2` (Tecla 2), `weapon_slot_3` (Tecla 3), `weapon_cycle_next` (Tecla Q / Scroll do Mouse / Botão R1): Seleção de armamento.

### 2.2. Gerenciamento de Sobrevivência
- **Blindagem (Armor):** $1.000$ pontos de vida base. Dano zerado resulta em detonação e falha da incursão.
- **Combustível (Fuel):** Capacidade máxima de $150.0$ unidades.
  - Queima Passiva (Pairando): $0.5\,unid/s$ (autonomia total: 300 segundos).
  - Queima em Aceleração Total: $1.2\,unid/s$ (autonomia total: 125 segundos).
  - Em $0.0$ unidades: Os motores cortam, a aeronave entra em autorrotação incontrolável e colide no solo/água em 3 segundos.
- **Reabastecimento e Reparo:**
  - **Porta-Aviões USS Vanguard (Heliponto Base Aliada):** Regenera $40\,HP/s$, $15\,Fuel/s$ até $150.0\text{ u}$ e descarrega todos os sobreviventes a bordo.
  - **Posto Avançado Terrestre (FOB / `FuelDepot`):** Heliponto secundário no Atol Central ($X: -250.0, Z: 120.0$) que reabastece a $12\,Fuel/s$ até a cota limite de $75.0$ unidades (50% do tanque), sem efetuar reparos nem descarregar civis.

### 2.3. Sistema de Armamento
- **Slot 1: Canhão Rotativo M134 (Arma Primária)**
  - Munição: $1.200$ projéteis. Cadência: 12 tiros/s. Dano: $14$ por tiro.
  - Projéteis físicos rápidos com rastro de emissão (*Glow* amarelo).
- **Slot 2: Foguetes Hydra 70 (Área / Estruturas)**
  - Munição: $32$ foguetes. Disparo em salvas duplas. Dano: $160$ em raio de $3.0$ m.
  - Arma primordial para abrir brechas em bunkers e destruir baterias antiaéreas.
- **Slot 3: Mísseis Teleguiados AGM-114 Hellfire (Pesado)**
  - Munição: $6$ mísseis. Trava no alvo mais próximo em um cone de $40^\circ$.
  - Dano: $650$. Foco em blindados pesados e componentes estruturais do chefe.

---

## 3. Mecânica de Resgate, Supressão e Fogo Cruzado

1. **Abrigos no Terreno:** Há 3 estruturas na ilha contendo sobreviventes (total de 12 especialistas distribuídos, sendo 4 por abrigo).
2. **Brecha:** Cada abrigo possui $300.0\text{ HP}$ de integridade estrutural. O jogador deve disparar foguetes ou canhão contra a estrutura até esgotar seus pontos de integridade, liberando os 4 sobreviventes no solo em um raio seguro de $2.5\text{ m}$ ao redor da fundação.
3. **Vulnerabilidade no Solo e Fogo Cruzado (Estilo *Choplifter*):**
   - Cada sobrevivente liberado no solo possui um `HealthComponent` com $30.0\text{ HP}$.
   - Civis expostos sofrem **dano colateral de explosões em área** (como foguetes Hydra do próprio jogador ou obuses de tanques inimigos) e de fogo cruzado no perímetro.
   - Isso cria uma cadeia tática obrigatória: o jogador deve usar armamento pesado (Hydra/Hellfire) para destruir blindados **antes** de romper o abrigo, e alternar para disparos cirúrgicos do **Canhão Vulcan** caso soldados ou drones se aproximem de sobreviventes já expostos. Se um civil morrer, emite-se `EventBus.civilian_killed`, reduzindo o total de *Personnel Tokens* possíveis na incursão.
4. **Anel de Embarque e Regra de Supressão de Perímetro:**
   - Ao pairar sobre a zona com altitude reduzida ($Y \le 1.2$ m) e velocidade horizontal reduzida ($\|v_{xz}\| \le 4.0\text{ m/s}$), projeta-se um anel circular holográfico no chão via decalque/shader (raio de detecção de $3.5\text{ m}$).
   - **Supressão / Contestação de Zona:** Se houver qualquer inimigo terrestre vivo (`MercenarySquad` ou `LightTank_IFV`) em um raio de $10.0\text{ m}$ do sobrevivente, o embarque entra em estado **SUPPRESSED** (o preenchimento do anel congela e o shader muda da cor ciano para vermelho-alerta) até que a ameaça próxima seja eliminada.
   - Sem supressão ativa, o anel preenche-se de $0^\circ$ a $360^\circ$ ao longo de $2.0$ segundos de permanência ininterrupta; a cada ciclo completo, 1 sobrevivente embarca.
5. **Lotação e Descarga:**
   - Capacidade Máxima Base: **5 passageiros**.
   - Ao atingir a capacidade máxima, o HUD emite alerta de *CABIN FULL*.
   - O jogador deve retornar ao Heliponto Aliado ($Y \le 1.2\text{ m}$) para descarregar os sobreviventes antes de resgatar os demais.

---

## 4. O Sistema Roguelite

### 4.1. Estrutura do Loop da Incursão (Run Loop)
1. **Lançamento:** O jogador parte do heliponto com carga máxima de munição e combustível, já acrescida dos modificadores permanentes comprados no Hangar (`MetaProgression`).
2. **Coleta de Suprimentos:** Inimigos neutralizados possuem $35\%$ de chance de soltar suprimentos coletáveis por sobrevoo rasante ou contato no raio de $3.0\text{ m}$:
   - **Caixa de Munição (`AmmoCrate`):** Restaura $25\%$ da munição máxima de todos os slots ($+300$ Vulcan, $+8$ Hydra, $+2$ Hellfire).
   - **Tambor de Combustível (`FuelDrum`):** Restaura $+30.0$ unidades de combustível.
3. **Drops de Firmware / Crates de Dados:** Destruir depósitos de dados da Aetheris ($150.0\text{ HP}$) emite `EventBus.data_crate_opened` e abre uma interface modal com árvore de cena pausada (`get_tree().paused = true`) para escolher **1 entre 3 Boons Táticos** sorteados sem repetição.
4. **Conclusão da Run:**
   - **Extração com Sucesso:** O chefe *Apex Bastion* é destruído e o helicóptero pousa na base. Todos os civis resgatados viram moedas de meta-progressão (*Personnel Tokens*).
   - **Abate / Queda por Combustível:** Todos os passageiros atualmente a bordo e os boons daquela run são perdidos. Apenas os sobreviventes descarregados previamente no heliponto durante a run são retidos no `MetaProgression`.

### 4.2. Catálogo de Boons Táticos da Run (Amostra para o MVP)
* `Overclock de Rotor`: +15% de velocidade máxima e aceleração; +10% de consumo de combustível.
* `Munição Perfurante`: Tiros de canhão atravessam o primeiro alvo atingido e causam +25% de dano a estruturas.
* `Guincho de Alta Potência`: Reduz o tempo de preenchimento do anel de resgate de $2.0$ s para $1.1$ s.
* `Tanques Selados Auxiliares`: Aumenta a capacidade de combustível para $130$ unidades e reduz a queima passiva em 15%.
* `Sistemas de Chaff/Flare`: Ao tomar travamento de míssil inimigo, solta automaticamente contra-medidas (cooldown de 12 s).

### 4.3. Meta-Progressão no Hangar (Permanente)
* **Engenharia de Estruturas:** Expande permanentemente a cabine de resgate (de 5 para até 8 passageiros).
* **Reforço de Blindagem:** Aumenta o HP máximo do helicóptero em escalões (+100 HP por nível).
* **Logística de Calibre:** Aumenta a capacidade de reserva de foguetes Hydra e mísseis Hellfire.

---

## 5. Ecossistema de Inimigos e Distribuição Híbrida do Mapa (Atol de Midway)

### 5.1. Elenco Tático de Inimigos Regulares (5 Arquétipos)
Todos os inimigos compartilham uma arquitetura modular baseada em `EnemyBase` + `HealthComponent` + `EnemyAIController` parametrizado via recursos `EnemyStatsData.tres`:

| Arquétipo | Camada Física | HP Base | Velocidade | Comportamento de IA e Ataque | Papel Tático e Arma Ideal |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **1. Infantaria Mercenária (`MercenarySquad`)** | `3` (`Enemies_Ground`) | $45.0$ | $3.5\text{ m/s}$ | Patrulha o perímetro dos abrigos; dispara rajadas leves a cada $1.8\text{ s}$ (alcance $22\text{ m}$, dano $12.0$). **Suprime o anel de resgate** se estiver a $\le 10.0\text{ m}$ dos civis. | Exige limpeza cirúrgica com **Canhão Vulcan (Slot 1)** para não ferir civis com explosões. |
| **2. Drone Caçador (`HunterDrone`)** | `4` (`Enemies_Air`) | $60.0$ | $14.0\text{ m/s}$ | Perseguidor aéreo na cota do jogador ($Y = 4.0\text{ m}$ a $1.2\text{ m}$); dispara plasma leve a cada $1.5\text{ s}$ (alcance $20\text{ m}$, dano $20.0$). | Pressiona o helicóptero durante o voo pairado de resgate; abatido com **Canhão Vulcan (Slot 1)**. |
| **3. Lancha de Patrulha (`PatrolBoat`)** | `3` (`Enemies_Ground`) | $180.0$ | $8.0\text{ m/s}$ | Navega em circuitos fechados na lagoa e costa; dispara metralhadora pesada a cada $2.0\text{ s}$ (alcance $32\text{ m}$, velocidade $45\text{ m/s}$, dano $35.0$). | Domínio marítimo; vulnerável a **Canhão Vulcan** e **Foguetes Hydra (Slot 2)**. |
| **4. Blindado Leve (`LightTank_IFV`)** | `3` (`Enemies_Ground`) | $320.0$ | $4.5\text{ m/s}$ | Patrulha estradas e acessos aos abrigos; dispara obuses explosivos de $30\text{ mm}$ a cada $3.0\text{ s}$ (alcance $36\text{ m}$, dano $95.0$, explosão de $2.0\text{ m}$ letal a civis). **Suprime o anel de resgate** ($\le 10.0\text{ m}$). | Deve ser eliminado **antes** da abertura do abrigo com **Foguetes Hydra (Slot 2)** ou **Hellfire (Slot 3)**. |
| **5. Bateria Antiaérea (`TurretSAM`)** | `3` (`Enemies_Ground`) | $240.0$ | $0.0\text{ m/s}$ | Sentinela estática em colinas; dispara míssil teleguiado a cada $4.0\text{ s}$ (alcance $40\text{ m}$, velocidade $28\text{ m/s}$, curva $2.5\text{ rad/s}$, dano $180.0$, $14.0\text{ HP}$). | Negação de área de longo alcance; alvo prioritário para **Foguetes Hydra** e **Mísseis Hellfire**. |

### 5.2. Dinâmica Híbrida do `SpawnDirector.gd` e Topografia Global ($2.500 \times 2.500\text{ m}$)
O mapa global abrange $2.500 \times 2.500\text{ m}$ ($X \in [-1250, +1250]$, $Z \in [-1250, +1250]$), dividido em 5 setores operacionais:
1. **Setor Sudeste (Força-Tarefa Vanguard):** Heliponto do porta-aviões USS Vanguard em $(800, 1.0, 950)$ onde o jogador surge e realiza reparos/desembarque de civis.
2. **Setor Central (O Atol de Midway):** Área de terra de $\sim 1.200 \times 800\text{ m}$ ($X \in [-600, 600], Z \in [-400, 400]$). Contém os 3 abrigos de civis restritos à máscara $X \in [-500, 500], Z \in [-350, 350]$, baterias SAM, bunkers e o posto avançado de combustível (FOB).
3. **Setor Noroeste (Águas Profundas):** Posição da nau-capitania canhoneira *Apex Bastion* em $(-900, 0, -900)$ e campos de minas flutuantes.
4. **Setor Norte (Plataforma Marítima):** Plataforma de dados marítima em $(200, 0, -1000)$ guarnecida por lanchas de patrulha.
5. **Setor Leste (Recifes e Ilhotas):** Posto de escuta SIGINT em $(900, 0, 100)$ e recifes costeiros.

A geografia do terreno é delimitada e os nós operacionais combinam sorteio inicial com resposta dinâmica da IA *ApexNet*:
1. **Alocação no Início da Incursão:**
   - **3 Abrigos de Reféns (`RescueShelter`):** Sorteados entre 6 coordenadas possíveis ($300.0\text{ HP}$, 4 civis cada).
   - **3 Esquadrões de Infantaria (`MercenarySquad`):** Posicionados guarnecendo diretamente os 3 abrigos sorteados.
   - **4 Baterias SAM (`TurretSAM`):** Distribuídas entre 8 colinas táticas.
   - **2 Blindados Leves (`LightTank_IFV`):** Posicionados nos anéis viários conectando os setores da ilha.
   - **2 Lanchas de Patrulha (`PatrolBoat`):** Alocadas na lagoa interna e no canal costeiro.
   - **2 Caixas de Dados (`DataCrate`):** Escondidas entre 4 bunkers secundários ($150.0\text{ HP}$).
2. **Reforços Reativos durante a Partida (*The Reactive Grid*):**
   - Sempre que um abrigo é rompido (`EventBus.shelter_destroyed`) ou um depósito de dados é aberto (`EventBus.data_crate_opened`), o `SpawnDirector` aciona uma onda de resposta tática: **2 `HunterDrone`** surgem no perímetro aéreo a $60.0\text{ m}$ convergindo sobre a posição do jogador e **1 `MercenarySquad`** avança pela rota terrestre mais próxima para tentar suprimir a zona de extração.

---

## 6. O Chefe do MVP: Canhoneiro Litorâneo *Apex Bastion*

Uma fragata automatizada de combate costeiro ancorada na saída da baía protegendo a estação de cabos submarinos.

- **Integridade Total:** $4.000$ HP distribuídos em partes modulares:
  - Torreta de Proa (Canhão Duplo 76mm): $800$ HP.
  - Torreta de Popa (Lançador Quádruplo de Mísseis): $800$ HP.
  - Núcleo de Comando / Reator: $2.400$ HP (só recebe dano após a queda de ao menos 1 das torretas).
- **Fase 1 (100% a 50% HP do Núcleo):**
  - O canhão duplo dispara saraivadas preditivas de projéteis pesados a cada $2.5$ segundos (velocidade de $55.0\text{ m/s}$, dano de $120.0$, raio de explosão de $2.5\text{ m}$).
  - Libera minas navais flutuantes a cada $6.0$ segundos que detonam por proximidade (raio de $3.5\text{ m}$, dano de $250.0$) se o helicóptero voar baixo sobre a água ($Y \le 1.5\text{ m}$).
- **Fase 2 (49% a 0% HP do Núcleo):**
  - Ativa defesas de ponto (CIWS) com cortina contínua de fogo traçante em leque de $60^\circ$ a cada $3.0$ segundos (velocidade de $70.0\text{ m/s}$, dano de $25.0$ por impacto).
  - Dispara salvas de 4 mísseis teleguiados lentos a cada $7.0$ segundos (velocidade de $20.0\text{ m/s}$, curva de $1.8\text{ rad/s}$, dano de $150.0$ cada, $14.0\text{ HP}$ destrutíveis com o canhão Vulcan).
- **Derrota:** Sequência de explosões encadeadas pelo casco, afundamento gradual da popa e emissão de `EventBus.boss_defeated("Apex Bastion")` e `EventBus.mission_accomplished()`.

---

## 7. Critérios de Aceitação do MVP (Definition of Done)

- [ ] **Voo e Física:** O nó `CharacterBody3D` do helicóptero responde a entradas com inércia perceptível, aceleração progressiva e inclinação de fuselagem proporcional.
- [ ] **Sobrevivência:** Consumo passivo e ativo de combustível validado; colisão catastrófica acionada após esgotamento do tanque.
- [ ] **Arsenal Triplo:** Alternância entre Canhão Vulcan, Foguetes Hydra e Mísseis Hellfire com limites de munição e comportamentos de balística/dano comprovados em teste.
- [ ] **Resgate e Capacidade:** Pelo menos 1 abrigo destrutível que libere sobreviventes; anel holográfico de resgate com contagem temporal de 2.0 s; limite de 5 passageiros respeitado e descarga no heliponto.
- [ ] **Loop Roguelite Integrado:** Destruição de crate concede seleção funcional de 3 boons com aplicação imediata de modificadores; falha na incursão reseta os boons e passageiros a bordo.
- [ ] **Geração Semi-Procedural:** Posições dos abrigos e das defesas inimigas mudam a cada reinício de incursão.
- [ ] **Confronto de Chefe:** O navio *Apex Bastion* opera suas duas fases de combate com torretas destruíveis antes de expor o reator.
- [ ] **Direção Visual:** Shader de água com profundidade e espuma litorânea, iluminação direcional forte com sombras nítidas e efeitos de pós-processamento HDR/Bloom ativos.