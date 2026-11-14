# 16_VISUAL_REFERENCE_INDEX.md: Índice Integrado de Referências Visuais

## Ordem obrigatória de consulta

1. `ART-REF-001` e `11_VISUAL_STYLE_GUIDE.md`: identidade, paleta, câmera,
   iluminação e materiais.
2. `WORLD-MAP-REF-002` e `12_WORLD_MAP_REFERENCE.md`: geografia macro e setores.
3. `SR-01` a `SR-05` e `13_SECTOR_BUILD_REFERENCES.md`: terreno, rotas e encontros.
4. `CR-01` a `CR-03` e `14_CONSTRUCTION_VISUAL_LIBRARY.md`: estruturas permanentes.
5. `VR-01` a `VR-03` e `15_VEHICLE_VISUAL_LIBRARY.md`: veículos, aeronaves e barcos.
6. `VC-01` a `VC-08` e `10_VISUAL_CONTRACT.md`: aceitação final por captura.

## Estrutura de arquivos

```text
assets/reference/visual_contract/
├── anchors/       # identidade visual raiz
├── baselines/     # VC-01 a VC-08, regressão visual
├── maps/          # geografia macro e histórico
├── sectors/       # SR-01 a SR-05, construção de cada setor
├── construction/  # CR-01 a CR-03, infraestrutura
├── vehicles/      # VR-01 a VR-03, entidades móveis e props
├── visual_tokens.json
├── shot_matrix.json
└── manifest.json
```

## Regra de conflito

Os dados numéricos e limites de `03_SPEC.md`, `05_DATA_SCHEMA.md` e
`10_VISUAL_CONTRACT.md` prevalecem sobre uma composição artística. As imagens
definem aparência e disposição; não autorizam novas mecânicas, entidades ou limites.
