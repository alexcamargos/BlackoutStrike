## Componente responsavel pelo gerenciamento de combustivel da aeronave.
##
## Controla o consumo passivo e ativo, a deteccao de pane seca e rotinas de reabastecimento.
class_name FuelComponent
extends Node

## Emitido sempre que o valor atual ou maximo de combustivel for alterado.
signal fuel_changed(current: float, max_fuel: float)

## Emitido no momento exato em que o combustivel atinge zero (pane seca).
signal fuel_depleted()

## Capacidade maxima de combustivel suportada pelo tanque.
@export var max_fuel: float = 150.0

## Nivel atual de combustivel disponivel.
@export var current_fuel: float = 150.0

## Taxa de consumo passivo por segundo durante voo estavel ou pairado (u/s).
@export var passive_burn_rate: float = 0.5

## Taxa de consumo ativo por segundo durante manobras de aceleracao (u/s).
@export var active_burn_rate: float = 1.2


## Executa o consumo passivo de combustivel ao longo do intervalo de tempo.
##
## Args:
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func consume_passive(delta: float) -> void:
	if delta <= 0.0 or is_empty():
		return
	_apply_burn(passive_burn_rate * delta)


## Executa o consumo ativo de combustivel ao longo do intervalo de tempo.
##
## Args:
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func consume_active(delta: float) -> void:
	if delta <= 0.0 or is_empty():
		return
	_apply_burn(active_burn_rate * delta)


## Reabastece o tanque com a quantidade especificada, respeitando o limite maximo.
##
## Args:
##     amount (float): Volume de combustivel a ser adicionado.
##
## Returns:
##     void
func refuel(amount: float) -> void:
	if amount <= 0.0:
		return
	var previous_fuel: float = current_fuel
	current_fuel = minf(max_fuel, current_fuel + amount)
	if not is_equal_approx(previous_fuel, current_fuel):
		fuel_changed.emit(current_fuel, max_fuel)


## Reabastece o tanque ate um teto restrito especifico (ex: FOB terrestre).
##
## Args:
##     amount (float): Volume de combustivel a ser adicionado.
##     cap_limit (float): Teto maximo permitido para este reabastecimento.
##
## Returns:
##     void
func refuel_capped(amount: float, cap_limit: float) -> void:
	if amount <= 0.0 or cap_limit <= 0.0:
		return
	var target_cap: float = minf(max_fuel, cap_limit)
	if current_fuel >= target_cap:
		return
	var previous_fuel: float = current_fuel
	current_fuel = minf(target_cap, current_fuel + amount)
	if not is_equal_approx(previous_fuel, current_fuel):
		fuel_changed.emit(current_fuel, max_fuel)


## Informa se o tanque esta totalmente esgotado.
##
## Args:
##     Nenhum.
##
## Returns:
##     bool: True se o nivel de combustivel for menor ou igual a zero; False caso contrario.
func is_empty() -> bool:
	return current_fuel <= 0.0


## Deduz o valor de queima de combustivel, limitando a zero e emitindo os sinais devidos.
##
## Args:
##     amount (float): Quantidade absoluta de combustivel a queimar.
##
## Returns:
##     void
func _apply_burn(amount: float) -> void:
	if amount <= 0.0 or is_empty():
		return
	var was_empty: bool = is_empty()
	current_fuel = maxf(0.0, current_fuel - amount)
	fuel_changed.emit(current_fuel, max_fuel)
	if not was_empty and is_empty():
		fuel_depleted.emit()
