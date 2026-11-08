## Definicao do esquema de dados para melhorias permanentes de Hangar.
##
## Representa um upgrade no Hangar adquirido utilizando Personnel Tokens.
class_name HangarUpgradeData
extends Resource

@export var id: String = "expand_cabin"
@export var title: String = "Cabine Estendida"
@export_multiline var description: String = "Aumenta permanentemente a capacidade de refens do R-9X."
@export var current_level: int = 0
@export var max_level: int = 3
@export var cost_per_level: Array[int] = [3, 6, 12]
@export var value_per_level: Array[float] = [6.0, 7.0, 8.0]
