## Testes unitarios do SpawnDirector e do sistema de ondas reativas.
extends GutTest

var director: SpawnDirector


func before_each() -> void:
	director = SpawnDirector.new()
	add_child_autofree(director)


func test_initial_layout_quantities() -> void:
	var layout: Dictionary = director.spawn_initial_layout()
	
	assert_eq(layout["shelters"].size(), 3, "Deve instanciar exatamente 3 abrigos.")
	assert_eq(layout["mercenaries"].size(), 3, "Deve instanciar 3 esquadroes de infantaria guarnecendo os abrigos.")
	assert_eq(layout["sams"].size(), 4, "Deve instanciar 4 baterias SAM.")
	assert_eq(layout["tanks"].size(), 2, "Deve instanciar 2 blindados leves IFV.")
	assert_eq(layout["boats"].size(), 2, "Deve instanciar 2 lanchas de patrulha.")
	assert_eq(layout["crates"].size(), 2, "Deve instanciar 2 caixas de dados.")


func test_initial_layout_no_overlap() -> void:
	var layout: Dictionary = director.spawn_initial_layout()
	
	# Verifica que abrigos possuem coordenadas distintas
	var shelter_positions: Array[Vector3] = []
	for s: Node3D in layout["shelters"]:
		assert_false(shelter_positions.has(s.position), "Abrigos nao podem ter posicoes sobrepostas.")
		shelter_positions.append(s.position)
	
	# Verifica que baterias SAM possuem coordenadas distintas
	var sam_positions: Array[Vector3] = []
	for sam: Node3D in layout["sams"]:
		assert_false(sam_positions.has(sam.position), "Baterias SAM nao podem ter posicoes sobrepostas.")
		sam_positions.append(sam.position)
		
	# Verifica que caixas de dados possuem coordenadas distintas
	var crate_positions: Array[Vector3] = []
	for c: Node3D in layout["crates"]:
		assert_false(crate_positions.has(c.position), "Caixas de dados nao podem ter posicoes sobrepostas.")
		crate_positions.append(c.position)


func test_reactive_wave_triggered_by_shelter_destroyed() -> void:
	watch_signals(director)
	var origin: Vector3 = Vector3(25.0, 0.0, -10.0)
	
	EventBus.shelter_destroyed.emit(origin, 4)
	
	assert_signal_emitted(director, "reactive_wave_dispatched", "Deve emitir reactive_wave_dispatched ao destruir abrigo.")
	var params: Array = get_signal_parameters(director, "reactive_wave_dispatched")
	assert_not_null(params, "Parametros do sinal nao podem ser nulos.")
	assert_eq(params[0], origin, "Origem da onda deve coincidir com o local do abrigo.")
	var units: Array = params[1] as Array
	assert_eq(units.size(), 3, "Onda reativa deve conter 3 unidades (2 drones + 1 infantaria).")
	
	# Verifica raio de spawn dos drones aereos (~60m)
	var drone_a: Node3D = units[0] as Node3D
	var dist_a: float = Vector2(drone_a.position.x - origin.x, drone_a.position.z - origin.z).length()
	assert_almost_eq(dist_a, 60.0, 1.0, "Drones aereos devem surgir no perimetro a 60m.")


func test_reactive_wave_triggered_by_data_crate_opened() -> void:
	watch_signals(director)
	
	EventBus.data_crate_opened.emit([])
	
	assert_signal_emitted(director, "reactive_wave_dispatched", "Deve emitir reactive_wave_dispatched ao abrir crate de dados.")
	var params: Array = get_signal_parameters(director, "reactive_wave_dispatched")
	assert_not_null(params, "Parametros do sinal nao podem ser nulos.")
	var units: Array = params[1] as Array
	assert_eq(units.size(), 3, "Onda reativa deve conter 3 unidades.")


func test_auto_spawn_on_ready_flag() -> void:
	var auto_director: SpawnDirector = SpawnDirector.new()
	auto_director.auto_spawn_on_ready = true
	add_child_autofree(auto_director)
	
	# Com auto_spawn_on_ready = true, o diretor deve instanciar abrigos como filhos ao entrar na arvore
	var shelters_found: int = 0
	for child in auto_director.get_children():
		if child is RescueShelter or child.name.begins_with("RescueShelter"):
			shelters_found += 1
	assert_eq(shelters_found, 3, "Auto spawn deve instanciar 3 abrigos automaticamente em _ready().")
