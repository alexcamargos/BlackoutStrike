## Ponte militar rustica de madeira sobre a agua rasa (Inspiracao Urban Strike & Sky Force).
##
## Conecta estuarios e ilhotas do Atol, permitindo a circulacao de veiculos terrestres
## e servindo de choke point tatico onde infantaria e blindados patrulham.
class_name WoodenTacticalBridge
extends StaticBody3D

## Comprimento da extensao da ponte em metros.
@export var bridge_length: float = 80.0

## Largura da pista da ponte em metros.
@export var bridge_width: float = 12.0

## Altura da superficie da ponte sobre o nivel da agua.
@export var deck_height: float = 0.65


func _ready() -> void:
	if not is_in_group("world_static"):
		add_to_group("world_static")
	collision_layer = 1
	collision_mask = 0
