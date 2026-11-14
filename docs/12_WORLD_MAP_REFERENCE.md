# 12_WORLD_MAP_REFERENCE.md: Referência Visual do Mapa Mundial

## 1. Finalidade

`WORLD-MAP-REF-001` é uma referência visual aprovada para a leitura macro do Atol de
Midway. Ela orienta a tela de mapa, briefing, seleção de missão e composição de
horizonte; não altera coordenadas, colisão, limites jogáveis ou o contrato de spawn
em `03_SPEC.md`.

- Arquivo: `res://assets/reference/visual_contract/maps/world_map_reference_01.png`
- SHA-256: `d48c45921f6654ca1404b33bb4048dee12ccbc20b8bb95b2574390116878ff97`
- Origem: representação original, gerada a partir do Guia de Estilo e da geografia
  documentada; não é cópia cartográfica de Urban Strike.

### Revisão de detalhamento setorial

`WORLD-MAP-REF-002` é a revisão candidata do mapa macro, criada após as pranchas de
setor. Ela preserva a composição de `WORLD-MAP-REF-001` e acrescenta: anel viário,
distritos de resgate, depósito de combustível e torres SAM no Atol; rotas seguras e
perímetro de minas no encontro do Apex; heliponto/canais na Plataforma Norte;
marcadores SIGINT, recifes perigosos e áreas de pouso no Leste; e logística/corredor
de retorno no USS Vanguard.

- Arquivo: `res://assets/reference/visual_contract/maps/world_map_reference_02.png`
- SHA-256: `50a25cfb25f69a8e5975a6c7f660b4c2a3fe7ce1f88a5cde59ecad494e9fa35f`
- Estado: referência macro ativa aprovada pelo responsável em 2026-11-14. Ela
  substitui `WORLD-MAP-REF-001`, que permanece somente como histórico.

## 2. Leitura geográfica obrigatória

| Região visual | Região canônica | Dados de jogo |
| --- | --- | --- |
| Grande atol central com lagoa | Setor Central — Midway | terra de 1.200 x 800 m, X [-600, 600], Z [-400, 400] |
| Navio em setor de mar profundo no noroeste | Apex Bastion | (-900, 0, -900) |
| Plataforma offshore e ilhotas ao norte | Plataforma marítima de dados | (200, 0, -1000) |
| Cadeia de recifes e micro-ilhas a leste | SIGINT / Recifes Leste | (900, 0, 100) |
| Porta-aviões no mar sudeste | USS Vanguard | (800, 1, 950) |
| Instalação de combustível no atol | FOB / FuelDepot | (-250, 0, 120) |
| Costa continental distante no sudoeste | Contexto fora da área jogável | sem colisão, spawn ou objetivo |

## 3. Regras de uso

- O mapa deve manter oceano azul-marinho, águas rasas turquesa, espuma clara,
  vegetação tropical escura, areia quente, rocha vulcânica e infraestrutura industrial
  compatíveis com `11_VISUAL_STYLE_GUIDE.md`.
- Ilhas pequenas, boias, canais e plataformas devem aumentar orientação e escala;
  não podem criar objetivos jogáveis que contradigam `MapBoundsData`.
- A costa continental é somente contexto narrativo e visual. O mundo jogável continua
  limitado a X/Z [-1250, 1250].
- Marcadores de UI finais devem ser implementados como elementos Godot vetoriais ou
  de HUD, e não rasterizados diretamente nesta imagem de referência.
