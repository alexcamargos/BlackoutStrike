# 14_CONSTRUCTION_VISUAL_LIBRARY.md: Biblioteca Visual de Construções

## 1. Finalidade

Esta biblioteca define a aparência geral das construções permanentes citadas no mapa
macro e nas pranchas setoriais. Ela serve de guia para modelagem, materiais, LODs e
posicionamento de props. Não substitui os assets finais exigidos pelo Contrato Visual
nem cria novas mecânicas ou locais fora de `03_SPEC.md`.

## 2. Pranchas de referência

| ID | Arquivo | Setores atendidos | Famílias de construção |
| --- | --- | --- | --- |
| CR-01 | `construction/construction_terrestrial_reference_01.png` | Atol Central | abrigo de resgate, FuelDepot, galpão, torre SAM/radar, torre de comunicações, ponte/causeway |
| CR-02 | `construction/construction_naval_reference_01.png` | Vanguard, Norte, Apex | superestrutura naval, heliponto offshore, píer logístico, plataforma de dados, doca de manutenção, baliza de minas |
| CR-03 | `construction/construction_sigint_reefs_reference_01.png` | Recifes Leste | posto SIGINT, torre de vigia, píer leve, gerador, clareira de pouso, baliza de recife |

## 3. Regras de construção

- Todos os edifícios usam materiais PBR com Albedo, Normal, ORM e Emissive conforme
  `10_VISUAL_CONTRACT.md`; nenhuma construção de produção pode usar primitive mesh
  visível.
- A estrutura primária é aço pintado, concreto armado ou rocha vulcânica. Corrosão,
  parafusos, juntas, placas, escadas, guarda-corpos, cabos e tubulações são detalhes
  obrigatórios de escala — não decoração opcional.
- Vanguard usa aço azul-cinza com detalhes de segurança amarelos; Aetheris usa
  antracite e vermelho-laranja apenas em sinalização, miras e eletrônica hostil.
- Construções no Atol devem respeitar praia, falésia e platôs já definidos. Estruturas
  offshore precisam deixar convés, passarela, ancoragem e água abaixo legíveis para
  a câmera tática.
- SIGINT e vigia usam volumes menores encaixados em rocha/vegetação, com silhueta de
  antena/radar visível de longe; os recifes mantêm águas rasas turquesa em volta.

## 4. Vinculação aos setores

- **Central Midway:** três RescueShelters distinguíveis, FuelDepot, galpões e torres
  SAM. Abrigos mantêm área livre de 2,5 m para liberar civis.
- **Vanguard:** convés, heliponto aliado, doca de reparo e logística de retorno.
- **Apex Bastion:** a construção principal é o boss modular; balizas e minas são
  elementos de arena, nunca edifícios de terra.
- **Plataforma Norte:** plataforma elevada com heliponto, radares, guindastes,
  tubos, píeres e ilhotas de apoio.
- **Recifes Leste:** posto SIGINT, geração elétrica, torres de vigia, pequenos
  píeres e balizas para canais.

## 5. Gate de implementação

Uma família só pode ser marcada como implementada quando seu asset final possui
arquivo, hash, licença, LOD0–LOD2, texturas contratadas e captura visual compatível
com a prancha correspondente.
