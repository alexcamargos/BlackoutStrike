## Recurso de configuracao de Boons taticos para incursao roguelite.
##
## Modificadores temporarios concedidos ao abrir caixas de dados durante a incursao.
class_name BoonData
extends Resource

enum TargetSystem {
	FLIGHT,
	ARMOR,
	FUEL,
	WEAPONS,
	RESCUE,
}

enum OperationType {
	MULTIPLY,
	ADD,
	UNLOCK_FLAG,
}

@export var id: String = "overclock_rotor"
@export var title: String = "Overclock de Rotor"
@export_multiline var description: String = "+15% Velocidade Maxima e Aceleracao, porem +10% Consumo de Combustivel."
@export var icon: Texture2D
@export var target_system: TargetSystem = TargetSystem.FLIGHT
@export var operation: OperationType = OperationType.MULTIPLY
@export var target_property_name: String = "max_speed"
@export var value: float = 1.15

@export var has_secondary_buff: bool = true
@export var secondary_property_name: String = "acceleration"
@export var secondary_operation: OperationType = OperationType.MULTIPLY
@export var secondary_value: float = 1.15

@export var has_drawback: bool = true
@export var drawback_property_name: String = "active_burn_rate"
@export var drawback_value: float = 1.10
