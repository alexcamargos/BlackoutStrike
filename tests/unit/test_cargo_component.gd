extends GutTest

## Bateria de testes unitarios para o componente de carga e resgate (CargoComponent).

var cargo: CargoComponent


func before_each() -> void:
	cargo = CargoComponent.new()
	cargo.max_capacity = 5
	cargo.current_occupants = 0
	cargo.boarding_duration = 2.0
	add_child_autofree(cargo)


func test_cargo_initial_state() -> void:
	assert_eq(cargo.max_capacity, 5, "Capacidade maxima inicial deve ser 5.")
	assert_eq(cargo.current_occupants, 0, "Cabine recem-instanciada deve estar vazia.")
	assert_false(cargo.is_full(), "Nao deve estar cheia inicialmente.")


func test_cargo_capacity_limit() -> void:
	watch_signals(cargo)
	watch_signals(EventBus)
	
	for i in range(5):
		assert_true(cargo.try_board_passenger(), "Deve embarcar passageiro com espaco livre.")
		assert_signal_emitted(cargo, "passenger_boarded", "Deve emitir passenger_boarded.")
		assert_signal_emitted(EventBus, "civilian_boarded", "Deve emitir EventBus.civilian_boarded.")
	
	assert_signal_emitted(cargo, "cabin_full", "Deve emitir cabin_full ao lotar.")
	assert_true(cargo.is_full(), "is_full() deve retornar true com 5 passageiros.")
	assert_false(cargo.try_board_passenger(), "Nao deve permitir embarque se a cabine estiver lotada.")
	assert_eq(cargo.current_occupants, 5, "Lotacao deve permanecer no valor maximo permitido.")


func test_unload_passengers_resets_cargo() -> void:
	watch_signals(cargo)
	cargo.current_occupants = 4
	
	var extracted_count: int = cargo.unload_all()
	
	assert_eq(extracted_count, 4, "Deve retornar a contagem correta de civis descarregados.")
	assert_eq(cargo.current_occupants, 0, "A cabine deve retornar a zero ocupantes apos a descarga.")
	assert_false(cargo.is_full(), "A cabine nao deve estar cheia apos a descarga.")
	assert_signal_emitted(cargo, "passengers_unloaded", "Deve emitir passengers_unloaded.")
