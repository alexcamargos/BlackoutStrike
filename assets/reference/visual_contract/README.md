# Visual Contract References

Este diretório receberá exclusivamente os oito PNGs aprovados definidos em
`docs/10_VISUAL_CONTRACT.md`. Não há imagens provisórias: uma imagem gerada sem
aprovação humana não é uma referência canônica.

`draft_concept_01.png` é a âncora de estilo aprovada `ART-REF-001`. Ela orienta a
linguagem visual geral por meio de `docs/11_VISUAL_STYLE_GUIDE.md`, mas não substitui
nenhum `VC-xx` nem pode ser usada em comparação automatizada.

As imagens `VC-01` a `VC-08` foram geradas a partir dessa âncora, normalizadas para
1920x1080 e aprovadas pelo responsável como baselines de regressão.

`world_map_reference_01.png` é a referência de geografia macro e composição do mapa
tático. Sua relação com os setores canônicos está em `docs/12_WORLD_MAP_REFERENCE.md`.

Após adicionar cada arquivo, calcule seu SHA-256 e preencha `manifest.json`. Também
adicione uma máscara PNG somente se a área excluída for inevitavelmente não
determinística e estiver justificada no manifesto.
