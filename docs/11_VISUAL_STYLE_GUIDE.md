# 11_VISUAL_STYLE_GUIDE.md: Guia de Estilo Visual Aprovado

## 1. Âncora de estilo

`ART-REF-001` é a âncora artística aprovada do projeto:

- Arquivo: `res://assets/reference/visual_contract/draft_concept_01.png`
- SHA-256: `989cbe47955f4faa6ff59e3a332a230aaa898787a98f7066fd2852b3a53d4fc6`
- Papel: define linguagem de materiais, paleta, composição, densidade de cenário e
  hierarquia de leitura.
- Limite: não é um screenshot de fixture e, portanto, não substitui nenhum baseline
  VC-01 a VC-08 nem habilita a aprovação automática de imagem.

Toda cena, asset e efeito visual deve seguir as regras abaixo. Os tokens
serializáveis ficam em `assets/reference/visual_contract/visual_tokens.json`.

## 2. Leitura de cena e câmera

1. A câmera é oblíqua, em perspectiva, com inclinação de 68 graus e FOV de 36 graus.
2. O helicóptero é a primeira leitura: em gameplay normal ocupa 7%–13% da tela e
   permanece separado visualmente do fundo por contraste de valor e rim light.
3. O oceano é a segunda leitura: azul profundo distante, turquesa em águas rasas e
   espuma branca somente em interseções costeiras, casco e rochas.
4. O cenário industrial ocupa o plano médio; falésias, vegetação e ilhotas definem
   profundidade no fundo. A cena não pode ter grandes vazios sem propósito tático.
5. Traçantes, travas e explosões são a terceira leitura. Eles guiam o olhar, mas não
   podem encobrir helicóptero, objetivos ou inimigos por mais de 0,25 s.

## 3. Linguagem de materiais e modelagem

- Superfícies militares usam metal pintado e desgastado: variação de roughness,
  bordas levemente gastas, painéis, rebites e juntas visíveis. Não usar chapas lisas
  de cor uniforme.
- O R-9X usa pintura azul-chumbo, canopy escuro reflexivo, rotor principal e rotor
  de cauda separados, pods de armas e silhueta assimétrica legível de cima.
- Aetheris usa casco antracite, detalhes industriais angulares e apenas emissivos
  hostis vermelho-laranja. Não usar azul aliado em elementos de facção inimiga.
- Construções, guindastes, contêineres e porta-aviões devem ter textura, decals ou
  elementos de malha que comuniquem escala. Geometria primitiva visível é proibida.
- Todos os modelos de produção precisam conter mapas Albedo, Normal, ORM e Emissive
  conforme resolução e orçamento definidos no Contrato Visual.

## 4. Paleta e hierarquia de cor

| Prioridade | Uso | Token |
| --- | --- | --- |
| 1 | Fogo aliado, impactos e interação positiva | `allied_tracer` / `positive_glow` |
| 2 | Risco inimigo, supressão e lock hostil | `hostile_alert` |
| 3 | Helicóptero, UI aliada e aço naval | `vanguard_steel` |
| 4 | Água, profundidade e atmosfera | `ocean_shallow`, `ocean_deep`, `fog_blue` |
| 5 | Praia, rocha, folhagem e indústria | `sand_warm`, `rock_dark`, `foliage_tropical`, `industrial_red` |

Amarelo é exclusivo para fogo/feedback aliado de alta prioridade. Vermelho-laranja é
exclusivo para ameaça, dano e supressão. Ciano é reservado para resgate e elementos
interativos aliados. Bloom nunca deve fazer um emissivo mudar a cor de identificação.

## 5. Iluminação, atmosfera e VFX

- Sol quente lateral a 55 graus; sombras PSSM nítidas até 180 m.
- O céu/horizonte recebe névoa azul profunda a partir de 120 m para organizar os
  planos sem apagar silhuetas.
- Glow é controlado: somente traçantes, laser, núcleo, HUD crítico e reflexos solares
  acima do limiar HDR entram em Bloom. Não aplicar emissivo ao casco completo.
- Explosões usam clarão, fogo, fumaça e fragmentos em camadas. Splash usa jato
  vertical e espuma radial. Todo VFX de combate tem vida finita e `one_shot`.
- O rotor wash aparece exclusivamente sobre água quando Y <= 1,8 m, esmaece acima
  dessa altura e não pode parecer uma textura estática.

## 6. HUD e interface

- HUD é técnico-militar, com barras angulares, corte de 45 graus e fundo azul-marinho
  translúcido. Informações críticas não compartilham a mesma cor de elementos
  decorativos.
- Combustível usa `fuel_warning` abaixo de 20%; blindagem, munição, passageiros e
  bússola ficam legíveis a 1920x1080 sem sobreposição.
- Retícula e lock usam ciano/amarelo aliado; lock inimigo confirmado usa
  vermelho-laranja. Scanlines são discretas, nunca reduzem o contraste do texto.

## 7. Checklist obrigatório de revisão

- A composição se parece com `ART-REF-001` quanto a câmera, hierarquia e densidade,
  sem copiar elementos que não pertencem ao jogo?
- Há qualquer `MeshInstance3D` com primitive mesh visível? Se sim, reprovar.
- Todas as facções, objetivos e perigos permanecem identificáveis em um screenshot?
- As cores estão dentro dos tokens e os emissivos respeitam sua função semântica?
- Há Normal/ORM/Emissive nos assets contratados, ou um material plano está ocultando
  asset ausente? Se sim, reprovar.
- A cena satisfaz seu baseline VC correspondente e o perfil de desempenho?
