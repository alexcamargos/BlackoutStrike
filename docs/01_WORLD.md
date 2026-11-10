# 01_WORLD.md: Universo Narrativo e Direção de Arte — Blackout Strike

## 1. Premissa Narrativa
Na era da hiperconvergência tecnológica, o controle físico da infraestrutura digital global tornou-se o ativo mais valioso da civilização. **Julian Vane**, bilionário da tecnologia e líder do conglomerado **Aetheris**, executa o plano *Blackout Soberano*: uma ofensiva combinada de ciberataques contra sistemas SCADA mundiais e incursões paramilitares físicas para sequestrar cabos submarinos, estações de ancoragem e centrais nucleares dedicadas. O objetivo é colapsar os governos democráticos para impor uma tecnocracia privada governada por sua inteligência artificial proprietária, a **ApexNet**.

A única linha de resposta não comprometida é a **JTF Vanguard** (Força-Tarefa Conjunta), operando o porta-aviões isolado *USS Vanguard*. Suas operações aéreas utilizam aeronaves de ataque e resgate com aviônica analógica, blindagem contra pulsos eletromagnéticos (EMP) e isolamento físico absoluto de redes externas (*air-gap*).

O jogador assume o papel do **Major Nathan "Rook" Cross** (codinome *Ghost-1*), pilotando o helicóptero de combate multimissão **R-9X Mohawk III**.

---

## 2. Justificativa Narrativa do Loop Roguelite

O formato roguelite está ancorado diretamente na ficção do jogo:

### 2.1. Por que as Incursões se Repetem? (The Reactive Grid)
A cada ataque do Major Cross contra as posições da Aetheris, os algoritmos preditivos de Julian Vane reagem em tempo real:
- Tropas e baterias antiaéreas são redistribuídas pela ilha.
- Os abrigos de reféns são realocados para novos bunkers industriais.
- A rotação de patrulhas e as frequências de contra-ataque mudam a cada sortida.

### 2.2. O Resgate como Motor da Meta-Progressão (Carrier Upgrades)
Sobreviventes resgatados não são mero placar; eles são levados para o *USS Vanguard* e colocados para trabalhar na expansão da infraestrutura militar aliada:
* **Engenheiros de Telecom:** Analisam hardware inimigo recuperado e desbloqueiam novos slots de armas e sensores no hangar.
* **Técnicos de Propulsão:** Refinam os compressores de turbina do R-9X, aumentando a eficiência do combustível e a taxa de subida/descida do guincho.
* **Especialistas em Guerra Eletrônica:** Desenvolvem contra-medidas (*flares*) e decodificadores que enfraquecem as defesas do chefe da área.

### 2.3. Boons Táticos em Tempo de Missão (In-Run Perks)
Ao destruir depósitos táticos da Aetheris ou hackear repetidoras de dados na ilha, o R-9X extrai firmware e componentes de campo improvisados, permitindo que a IA tática embarcada de Cross aplique melhorias pontuais válidas apenas para a duração daquela missão (ex: projéteis perfurantes, refrigeração líquida para o canhão, blindagem reativa).

---

## 3. Direção de Arte e Identidade Visual

O visual do jogo é governado pelo contrato mensurável em
[`10_VISUAL_CONTRACT.md`](10_VISUAL_CONTRACT.md). Referências a jogos externos são
somente contexto criativo e não constituem critério de aceite.

### 3.1. Iluminação e Renderização PBR
- **Sol Tropical Inclemente:** Iluminação direcional primária quente com sombras em cascata nítidas e profundas projetadas pelas falésias e prédios sobre o mar.
- **Materiais Metálicos Desgastados:** Fuselagem da aeronave e blindagem dos tanques com canais metálicos (~0.8) e rugosidade calibrada (0.2 a 0.4), gerando brilhos especulares intensos durante as curvas e rolagens.
- **Pós-Processamento:** Os valores de Glow, SSAO, névoa e tonemap são os valores
  numéricos estabelecidos no Contrato Visual.

### 3.2. Água Hiper-Estilizada
- Oceano dinâmico em degradê: turquesa translúcido nas faixas de areia branca da praia, aprofundando para azul-marinho denso nas trincheiras oceânicas.
- Linhas de espuma geradas proceduralmente pelo shader onde a malha da água intercepta terrenos rochosos e cascos de navios (*depth-fade intersection*).
- **Rotor Wash Interativo:** Quando o R-9X voa baixo, o deslocamento de ar projeta um anel expansivo de ondulações e borrifos de água no mar logo abaixo da aeronave.

### 3.3. Câmera
- Câmera em perspectiva com ângulo oblíquo acentuado (~68° em relação ao solo) e campo de visão baixo ($FOV = 36^\circ$), combinando leitura espacial isométrica clássica com sensação de profundidade e volumetria vertical.
