# 13_SECTOR_BUILD_REFERENCES.md: Pranchas de Construção por Setor

## 1. Uso e limite

Estas pranchas convertem a geografia macro de `WORLD-MAP-REF-001` em referências de
construção. Elas orientam massa de terreno, rotas, densidade de props, zonas de
combate e leitura visual. As coordenadas, limites de mundo, spawns e contratos de
jogabilidade em `03_SPEC.md` e `05_DATA_SCHEMA.md` continuam sendo a fonte canônica.

Cada referência precisa de aprovação do responsável antes de se tornar baseline
visual de setor. Não deve ser importada como textura runtime nem interpretada como
uma malha diretamente utilizável.

## 2. Setores

### SR-01 — Atol Central de Midway

- Arquivo: `res://assets/reference/visual_contract/sectors/sector_central_midway_reference_01.png`
- Geometria: anel de praia e falésias em torno da lagoa; platôs industriais e
  ilhas interiores conectadas por pontes/causeways.
- Construir primeiro: faixa de praia baixa, falésias Y=0,5–6,0, platôs Y=0,5,
  três clusters de `RescueShelter`, rotas de blindado e helipontos/áreas seguras.
- Leitura tática: três distritos de resgate separados, linhas de visão em colinas,
  estradas para reforços e canais rasos sem criar novos objetivos fora do spec.

### SR-02 — Inserção Naval USS Vanguard

- Arquivo: `res://assets/reference/visual_contract/sectors/sector_vanguard_reference_01.png`
- Geometria: porta-aviões em mar aberto, heliponto aliado, píer de apoio, barcos de
  serviço e rotas de navegação marcadas por boias.
- Construir primeiro: convés 150 x 36 m, spawn em (800, 1, 950), `AllyBaseHelipad`,
  áreas de reparo/desembarque e silhueta legível do porta-aviões.
- Leitura tática: área aliada segura, pista visual clara para retorno com civis e
  horizonte oceânico. O cenário de apoio tem colisão estática e a plataforma
  offshore aceita pouso. Os serviços da base continuam no heliponto do navio.

### SR-03 — Arena Oceânica Apex Bastion

- Arquivo: `res://assets/reference/visual_contract/sectors/sector_apex_bastion_reference_01.png`
- Geometria: arena de mar profundo com `Apex Bastion`, rochedos periféricos,
  corredores de aproximação, boias e campos de minas separados.
- Construir primeiro: boss em (-900, 0, -900), rotas abertas de helicóptero,
  mina flutuante, espuma contra casco/rochas e cobertura visual mínima.
- Leitura tática: núcleo e torretas legíveis, minas nunca sobrepostas à rota de
  fuga, bordas de recife não devem aprisionar a aeronave.

### SR-04 — Plataforma Norte de Dados

- Arquivo: `res://assets/reference/visual_contract/sectors/sector_north_platform_reference_01.png`
- Geometria: plataforma modular sobre pilares, convés alto, heliponto, antenas,
  guindastes, tubulação, píeres e duas ilhotas de serviço.
- Construir primeiro: volume da plataforma em (200, 0, -1000), níveis verticalmente
  legíveis, pontos de cobertura, ancoradouros de `PatrolBoat` e canal de chegada.
- Leitura tática: o helicóptero deve distinguir teto de pouso, passarelas e água;
  detalhes verticais não podem bloquear a câmera oblíqua.

### SR-05 — Recifes Leste e Posto SIGINT

- Arquivo: `res://assets/reference/visual_contract/sectors/sector_east_reefs_reference_01.png`
- Geometria: micro-ilhas, jardins de coral, canais profundos, falésias de vigia e
  posto SIGINT com radar, satélite, gerador e píer.
- Construir primeiro: marco SIGINT em (900, 0, 100), passagens costeiras, recifes
  como barreiras visuais e áreas pequenas de pouso seguro.
- Leitura tática: água rasa turquesa deve comunicar recife; canais navegáveis e
  pontos altos devem ser identificáveis a partir da câmera de missão.

## 3. Gate de implementação

Antes de considerar um setor concluído, a cena correspondente deve preservar sua
posição canônica, não usar primitive mesh visível, usar os tokens de
`visual_tokens.json` e incluir captura de comparação contra a prancha aprovada.
