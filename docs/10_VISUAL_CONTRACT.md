# 10_VISUAL_CONTRACT.md: Contrato Visual Determinístico

## 1. Finalidade e precedência

Este documento é o contrato de aceitação visual do *Blackout Strike*. Ele substitui
expressões subjetivas como "acabamento Sky Force", "detalhado", "intenso" e
"aceitável" por dados de produção e por imagens de referência aprovadas. Em caso de
conflito, este documento prevalece sobre a direção de arte descritiva em
`01_WORLD.md` e sobre o fallback de assets em `07_ASSETS.md`.

Nenhuma build de distribuição é visualmente aceita sem todos os baselines deste
contrato aprovados. Uma imagem somente pode ser marcada como aprovada pelo
responsável do projeto; um agente não pode criar ou autoaprovar um baseline.

`ART-REF-001`, em `assets/reference/visual_contract/draft_concept_01.png`, foi
aprovada como âncora de estilo geral. Sua aplicação está definida em
`11_VISUAL_STYLE_GUIDE.md`; ela não substitui os baselines de fixture desta seção.

## 2. Ambiente canônico de captura e desempenho

| Parâmetro | Valor contratual |
| --- | --- |
| Engine | Godot 4.3.x Forward+ / Vulkan |
| Sistema | Windows 11 64-bit |
| Resolução | 1920 x 1080, escala 100%, VSync desligado |
| Hardware-alvo | NVIDIA RTX 3060 12 GB ou equivalente, driver registrado no relatório |
| Preset | `High`, sem resolução dinâmica |
| Desempenho | média >= 60 FPS e percentil de 1% >= 50 FPS em uma rota de 120 s |
| Seed | `VisualContract.seed = 20261110` |

O relatório deve registrar versão exata da engine, commit, GPU, driver, resolução e
resultados de frame time. Capturas de hardware ou engine diferentes não substituem o
baseline sem nova aprovação.

## 3. Baselines obrigatórios

As imagens abaixo devem ser entregues pelo responsável em PNG sem perdas, 1920 x
1080, antes da aprovação da build. O manifesto em
`assets/reference/visual_contract/manifest.json` guarda seu hash SHA-256 e status.

| ID | Arquivo | Estado e composição fixa |
| --- | --- | --- |
| VC-01 | `VC-01_spawn_carrier.png` | Spawn no USS Vanguard; helicóptero entre 7% e 13% da área útil. |
| VC-02 | `VC-02_low_flight_ocean.png` | Voo a Y=1.2 sobre oceano; rotor wash visível. |
| VC-03 | `VC-03_coastal_combat.png` | Combate costeiro com 1 tanque, traçantes e espuma. |
| VC-04 | `VC-04_rescue_suppressed.png` | Civil suprimido; anel integral vermelho. |
| VC-05 | `VC-05_boss_phase_2.png` | Apex Bastion na fase 2; CIWS, emissivo do núcleo e casco legíveis. |
| VC-06 | `VC-06_hud_target_lock.png` | HUD 1080p com trava de alvo e barras sem corte. |
| VC-07 | `VC-07_sunset_island.png` | Ilha, praia, falésia e props de escala. |
| VC-08 | `VC-08_explosion_water.png` | Explosão naval e splash; partículas mascaradas na comparação. |

Para cada baseline, a implementação deve registrar em uma cena de fixture a câmera,
posição do jogador, estado da missão e seed. A diferença é avaliada por SSIM >= 0,97
fora das máscaras em `masks/`; pixels de UI e partículas só são ignorados quando a
máscara correspondente estiver listada no manifesto.

## 4. Paleta e materiais contratados

| Classe | Albedo/base | Metallic | Roughness | Emissão |
| --- | --- | ---: | ---: | --- |
| R-9X Vanguard | `#2A3847` | 0,80 | 0,25 | nenhum no casco |
| Aetheris | `#1F2226` | 0,70 | 0,32 | miras `#D9381E`, energia >= 2,50 |
| Canopy R-9X | `#101923` | 0,55 | 0,12 | nenhum |
| Traçante aliado | `#FFD35A` | n/a | n/a | energia >= 4,00 |
| Traçante hostil | `#D9381E` | n/a | n/a | energia >= 3,00 |
| Oceano raso/profundo | `#14A6B8` / `#031438` | 0,20 | 0,12 | nenhum |

Texturas de personagem, helicóptero e chefe usam Albedo, Normal, ORM e Emissive,
2048 x 2048; ambiente usa os mesmos canais em 1024 x 1024. Não é permitido usar
uma cor plana como substituto de um canal obrigatório.

## 5. Geometria de produção

| Asset ID | Arquivo obrigatório | Partes obrigatórias | Orçamento LOD0 |
| --- | --- | --- | ---: |
| MODEL_PLAYER_R9X_V1 | `assets/models/player/r9x_mohawk.glb` | fuselagem, canopy, rotor principal, rotor de cauda, pods e hardpoints | 12.000–18.000 triângulos |
| MODEL_BOSS_APEX_V1 | `assets/models/boss/apex_bastion.glb` | casco, torre de proa, CIWS de popa, núcleo | 20.000–35.000 triângulos |
| MODEL_ENEMY_SET_V1 | assets explícitos no manifesto | cinco arquétipos e partes móveis contratadas | 1.000–8.000 por entidade |
| MODEL_WORLD_SET_V1 | assets explícitos no manifesto | porta-aviões, abrigos, terreno, palmeiras, contêineres e guindastes | conforme manifesto |

Todo modelo de produção precisa ter LOD0, LOD1 e LOD2, IDs de nó estáveis e hash no
manifesto. `BoxMesh`, `CapsuleMesh`, `CylinderMesh`, `SphereMesh`, `PlaneMesh` e
`QuadMesh` são proibidos como geometria visível em `scenes/` de distribuição.
Eles são permitidos apenas em `CollisionShape3D`, `Area3D`, fixtures de teste e gizmos.

## 6. Iluminação e pós-processamento

- `DirectionalLight3D`: elevação 55 graus, azimute -40 graus, cor `#FFF0D9`,
  PSSM com 4 splits e distância de 180 m.
- Névoa: início 120 m, cor `#122233`.
- Tonemap: Filmic, exposure 1,05, white 1,20.
- Glow: ativo, intensidade 0,85, strength 1,05, threshold HDR 1,15.
- SSAO: ativo, radius 1,5, intensity 1,8, power 1,5.

## 7. Processo de aceitação

1. O responsável adiciona e aprova os oito PNGs e atualiza seus hashes.
2. A equipe cria fixtures reproduzíveis e máscaras mínimas para regiões não
determinísticas.
3. O executor Vulkan captura a cena e compara a imagem com o baseline.
4. O validador de assets confirma modelos, hashes, canais de textura e ausência de
primitivas visíveis.
5. A build é aceita somente quando testes lógicos, de integração, de assets, visuais
e desempenho forem aprovados.

Até a etapa 1, o estado do contrato é **BLOCKED_BY_REFERENCE_APPROVAL**, e nenhuma
declaração de fidelidade visual pode ser feita.
