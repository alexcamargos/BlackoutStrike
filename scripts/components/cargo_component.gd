## Componente responsavel pelo gerenciamento de passageiros e carga do helicoptero.
##
## Controla o limite de sobreviventes a bordo, fluxo de embarque com temporizacao,
## estado de cabine cheia e descarregamento no heliponto aliado.
class_name CargoComponent
extends Node

## Emitido quando um novo sobrevivente embarca com sucesso na cabine.
signal passenger_boarded(current_occupants: int, max_capacity: int)

## Emitido quando a capacidade maxima de passageiros e alcancada.
signal cabin_full()

## Emitido quando passageiros sao desembarcados no heliponto aliado.
signal passengers_unloaded(extracted_count: int)

## Capacidade maxima base de sobreviventes a bordo.
@export var max_capacity: int = 5

## Quantidade de civis atualmente na cabine.
@export var current_occupants: int = 0

## Tempo em segundos de permanencia pairada necessaria para embarcar 1 passageiro.
@export var boarding_duration: float = 2.0


## Tenta embarcar um passageiro na cabine.
##
## Args:
##     Nenhum.
##
## Returns:
##     bool: True se o passageiro foi embarcado; False se a cabine estiver cheia.
func try_board_passenger() -> bool:
	if is_full():
		cabin_full.emit()
		return false
	
	current_occupants += 1
	passenger_boarded.emit(current_occupants, max_capacity)
	
	if EventBus != null:
		EventBus.civilian_boarded.emit(current_occupants, max_capacity)
	
	if is_full():
		cabin_full.emit()
	
	return true


## Desembarca todos os sobreviventes da aeronave, esvaziando a capacidade da cabine.
##
## Args:
##     Nenhum.
##
## Returns:
##     int: Quantidade de civis desembarcados.
func unload_all() -> int:
	var extracted_count: int = current_occupants
	current_occupants = 0
	passengers_unloaded.emit(extracted_count)
	return extracted_count


## Verifica se a cabine atingiu a lotacao maxima permitida.
##
## Args:
##     Nenhum.
##
## Returns:
##     bool: True se a ocupacao atual for igual ou superior a capacidade maxima.
func is_full() -> bool:
	return current_occupants >= max_capacity
