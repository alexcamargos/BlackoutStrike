# 15_VEHICLE_VISUAL_LIBRARY.md: Biblioteca Visual de Veículos

## 1. Finalidade

As pranchas desta biblioteca definem silhueta, materiais, modularidade e linguagem
de facção para veículos terrestres, aeronaves, drones e embarcações. Elas não criam
novos arquétipos jogáveis: as entidades funcionais continuam sendo as registradas em
`03_SPEC.md` e `05_DATA_SCHEMA.md`.

## 2. Pranchas de referência

| ID | Arquivo | Cobertura principal |
| --- | --- | --- |
| VR-01 | `vehicles/vehicle_ground_reference_01.png` | `LightTank_IFV`, `TurretSAM` e veículos de logística/cenário |
| VR-02 | `vehicles/vehicle_air_reference_01.png` | R-9X Mohawk III, `HunterDrone` e props aéreos de convés |
| VR-03 | `vehicles/vehicle_maritime_reference_01.png` | `PatrolBoat`, Apex Bastion, USS Vanguard, reboque, minas e boias |

## 3. Contratos por família

### Terrestres

- `LightTank_IFV`: chassi de esteiras, torre móvel, canhão 30 mm, ótica emissiva e
  blindagem antracite; a torre deve ser um nó separado para coincidir com o vetor de
  disparo.
- `TurretSAM`: base estática costeira, lançador/óptica desacoplados, superfície de
  concreto e trilhos/escadas para comunicar escala.
- Caminhões, buggy, recovery truck e checkpoint são props de contexto. Não recebem
  AI, dano ou spawn sem alteração explícita da especificação.

### Aéreos

- R-9X: fuselagem, canopy, rotor principal, rotor de cauda, pods, hardpoints e
  `MuzzleMarkers` permanecem módulos distintos. A pintura Vanguard é `#2A3847` com
  metal 0,80 e roughness 0,25.
- `HunterDrone`: silhueta compacta não humanoide, óticas hostis vermelho-laranja e
  leitura clara de frente/cima para a câmera oblíqua.
- Caças de convés e tratores são exclusivamente adereços estáticos do USS Vanguard.

### Marítimos

- `PatrolBoat`: casco leve, torreta móvel e sensoriamento hostil; não confundir sua
  escala com a do Apex.
- Apex Bastion: casco principal, torreta de proa, CIWS de popa e núcleo retrátil
  precisam ser malhas/nós separados, obedecendo a lógica do chefe.
- USS Vanguard, rebocadores, boias e minas definem escala e rotas. Minas são perigo
  funcional somente quando instanciadas pela arena do chefe.

## 4. Regras comuns

- Usar Albedo, Normal, ORM e Emissive; painéis, parafusos, juntas, antenas, escadas,
  guarda-corpos e desgaste por sal são obrigatórios para leitura de escala.
- Vanguard usa azul-cinza `#2A3847`; Aetheris usa antracite `#1F2226` e vermelho
  `#D9381E` somente para ópticas, sinalização e emissão hostil.
- Não usar `BoxMesh`, `CapsuleMesh`, `CylinderMesh`, `SphereMesh`, `PlaneMesh` ou
  `QuadMesh` como geometria visível em cenas de produção.
- O asset final deve ter LOD0–LOD2, hash, licença e captura de conformidade visual
  antes de ser integrado.
