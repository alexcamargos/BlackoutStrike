extends GutTest

## Bateria de testes unitarios para o componente de combustivel (FuelComponent).

var fuel_component: FuelComponent


func before_each() -> void:
	fuel_component = FuelComponent.new()
	fuel_component.max_fuel = 100.0
	fuel_component.current_fuel = 100.0
	fuel_component.passive_burn_rate = 1.0
	fuel_component.active_burn_rate = 2.0
	add_child_autofree(fuel_component)


func test_fuel_initial_state() -> void:
	var fresh_component: FuelComponent = FuelComponent.new()
	add_child_autofree(fresh_component)
	assert_eq(fresh_component.max_fuel, 100.0, "O teto padrao de combustivel deve ser 100.0.")
	assert_eq(fresh_component.current_fuel, 100.0, "O combustivel inicial padrao deve ser 100.0.")
	assert_almost_eq(fresh_component.passive_burn_rate, 0.7, 0.001, "Queima passiva padrao deve ser 0.7 u/s.")
	assert_almost_eq(fresh_component.active_burn_rate, 1.6, 0.001, "Queima ativa padrao deve ser 1.6 u/s.")
	assert_false(fresh_component.is_empty(), "Componente recem-instanciado nao deve estar vazio.")


func test_fuel_depletes_passively_over_time() -> void:
	fuel_component.consume_passive(1.0)
	assert_almost_eq(fuel_component.current_fuel, 99.0, 0.01, "O combustivel deve drenar passivamente.")


func test_fuel_depletes_actively_over_time() -> void:
	fuel_component.consume_active(1.0)
	assert_almost_eq(fuel_component.current_fuel, 98.0, 0.01, "O combustivel deve drenar ativamente.")


func test_fuel_triggers_signal_on_empty() -> void:
	watch_signals(fuel_component)
	fuel_component.consume_active(50.0) # Reduz 100 unidades a 2.0 u/s
	assert_signal_emitted(fuel_component, "fuel_depleted", "O sinal de pane seca deve ser emitido quando atingir zero.")
	assert_eq(fuel_component.current_fuel, 0.0, "O combustivel nao deve admitir valores negativos.")
	assert_true(fuel_component.is_empty(), "is_empty() deve retornar true com combustivel zerado.")


func test_fuel_changed_signal_emitted_on_burn() -> void:
	watch_signals(fuel_component)
	fuel_component.consume_passive(5.0)
	assert_signal_emitted(fuel_component, "fuel_changed", "Deve emitir fuel_changed ao queimar combustivel.")


func test_refuel_increases_fuel_and_emits_signal() -> void:
	fuel_component.current_fuel = 40.0
	watch_signals(fuel_component)
	fuel_component.refuel(30.0)
	assert_almost_eq(fuel_component.current_fuel, 70.0, 0.01, "Reabastecimento deve somar combustivel.")
	assert_signal_emitted(fuel_component, "fuel_changed", "Deve emitir fuel_changed no reabastecimento.")


func test_refuel_clamps_to_max_fuel() -> void:
	fuel_component.current_fuel = 90.0
	fuel_component.refuel(30.0)
	assert_eq(fuel_component.current_fuel, 100.0, "Reabastecimento nao deve exceder max_fuel.")


func test_refuel_ignores_non_positive_amounts() -> void:
	fuel_component.current_fuel = 50.0
	watch_signals(fuel_component)
	fuel_component.refuel(0.0)
	fuel_component.refuel(-10.0)
	assert_eq(fuel_component.current_fuel, 50.0, "Quantidades nao positivas de reabastecimento devem ser ignoradas.")
	assert_signal_not_emitted(fuel_component, "fuel_changed", "Nao deve emitir sinal quando reabastecimento for invalido.")


func test_consume_ignores_non_positive_deltas() -> void:
	fuel_component.consume_passive(0.0)
	fuel_component.consume_passive(-1.0)
	fuel_component.consume_active(0.0)
	fuel_component.consume_active(-1.0)
	assert_eq(fuel_component.current_fuel, 100.0, "Deltas invalidos nao devem alterar combustivel.")


func test_empty_fuel_does_not_retrigger_depleted_signal() -> void:
	fuel_component.current_fuel = 0.0
	watch_signals(fuel_component)
	fuel_component.consume_passive(1.0)
	fuel_component.consume_active(1.0)
	assert_signal_not_emitted(fuel_component, "fuel_depleted", "Nao deve reemitir fuel_depleted se ja estiver vazio.")
