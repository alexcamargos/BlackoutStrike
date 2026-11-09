## Diretor de instanciacao semi-procedural e ondas reativas (The Reactive Grid).
##
## Distribui abrigos, postos de dados e guarnicoes hostis na geografia da ilha no inicio da incursao
## e responde dinamicamente a quebra de abrigos e crates com reforcos aereos e terrestres.
class_name SpawnDirector
extends Node3D

## Sinal emitido ao acionar uma onda de reforco reativo.
signal reactive_wave_dispatched(origin: Vector3, units: Array[Node3D])

## Cenas de entidades instanciadas pelo diretor.
@export var shelter_scene: PackedScene
@export var data_crate_scene: PackedScene
@export var mercenary_squad_scene: PackedScene
@export var turret_sam_scene: PackedScene
@export var light_tank_scene: PackedScene
@export var patrol_boat_scene: PackedScene
@export var hunter_drone_scene: PackedScene

## Nós contêineres opcionais para organizacao hierarquica na cena principal.
@export var enemies_container: Node3D
@export var shelters_container: Node3D
@export var crates_container: Node3D

## Coordenadas candidatas pre-marcadas na geografia fixa do atol (350x350m).
@export var candidate_shelter_points: Array[Vector3] = [
	Vector3(-70.0, 0.0, -50.0),
	Vector3(-40.0, 0.0, 45.0),
	Vector3(50.0, 0.0, -60.0),
	Vector3(65.0, 0.0, 30.0),
	Vector3(-15.0, 0.0, -85.0),
	Vector3(20.0, 0.0, 75.0),
]

@export var candidate_sam_points: Array[Vector3] = [
	Vector3(-110.0, 5.0, -90.0),
	Vector3(-95.0, 4.0, 60.0),
	Vector3(-30.0, 6.0, -110.0),
	Vector3(0.0, 7.0, 110.0),
	Vector3(80.0, 5.0, -100.0),
	Vector3(105.0, 4.0, -20.0),
	Vector3(90.0, 6.0, 80.0),
	Vector3(-60.0, 5.0, 0.0),
]

@export var candidate_data_crate_points: Array[Vector3] = [
	Vector3(-85.0, 0.0, -25.0),
	Vector3(-20.0, 0.0, 95.0),
	Vector3(45.0, 0.0, -90.0),
	Vector3(85.0, 0.0, 45.0),
]

@export var candidate_light_tank_points: Array[Vector3] = [
	Vector3(-50.0, 0.0, -20.0),
	Vector3(30.0, 0.0, -40.0),
	Vector3(-25.0, 0.0, 50.0),
	Vector3(40.0, 0.0, 55.0),
]

@export var candidate_patrol_boat_points: Array[Vector3] = [
	Vector3(-130.0, -0.5, 0.0),
	Vector3(130.0, -0.5, -40.0),
	Vector3(0.0, -0.5, -135.0),
	Vector3(20.0, -0.5, 135.0),
]

## Distancia radial de surgimento dos drones em ondas reativas (em metros).
const DRONE_REACTIVE_RADIUS: float = 60.0

## Se verdadeiro, dispara a instanciacao do layout inicial automaticamente em _ready().
@export var auto_spawn_on_ready: bool = false

## Referencia local ao jogador para alinhamento de reforcos aereos.
var player_ref: Node3D = null


## Inicializa o diretor, conecta aos sinais reativos do EventBus e carrega cenas padrao.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _ready() -> void:
	_load_default_scenes()
	_collect_marker_spawn_points()
	
	if EventBus != null:
		if not EventBus.shelter_destroyed.is_connected(_on_shelter_destroyed):
			EventBus.shelter_destroyed.connect(_on_shelter_destroyed)
		if not EventBus.data_crate_opened.is_connected(_on_data_crate_opened):
			EventBus.data_crate_opened.connect(_on_data_crate_opened)
	
	if auto_spawn_on_ready:
		spawn_initial_layout()


## Distribui semi-proceduralmente o layout inicial da missao sem sobreposicoes.
##
## Args:
##     Nenhum.
##
## Returns:
##     Dictionary: Dicionario agrupando as instancias criadas por categoria.
##
## Raises:
##     Nenhuma excecao levantada.
func spawn_initial_layout() -> Dictionary:
	var result: Dictionary = {
		"shelters": [],
		"mercenaries": [],
		"sams": [],
		"tanks": [],
		"boats": [],
		"crates": [],
	}
	
	# 1. 3 Abrigos sorteados entre 6 pontos
	var shelter_indices: Array[int] = _pick_random_indices(candidate_shelter_points.size(), 3)
	for idx: int in shelter_indices:
		var pos: Vector3 = candidate_shelter_points[idx]
		var shelter: Node3D = _instantiate_or_placeholder(shelter_scene, "RescueShelter", pos, shelters_container)
		result["shelters"].append(shelter)
		
		# 3 Esquadroes de infantaria guarnecendo diretamente cada abrigo sorteado (offset de 3m)
		var merc_pos: Vector3 = pos + Vector3(2.5, 0.0, 2.0)
		var merc: Node3D = _instantiate_or_placeholder(mercenary_squad_scene, "MercenarySquad", merc_pos, enemies_container)
		var merc_ai: EnemyAIController = merc.get_node_or_null("EnemyAIController") as EnemyAIController
		if merc_ai != null:
			merc_ai.patrol_waypoints = [
				pos + Vector3(6.0, 0.0, 4.0),
				pos + Vector3(4.0, 0.0, -6.0),
				pos + Vector3(-6.0, 0.0, -4.0),
				pos + Vector3(-4.0, 0.0, 6.0)
			]
		result["mercenaries"].append(merc)
	
	# 2. 4 Baterias SAM distribuidas entre 8 pontos
	var sam_indices: Array[int] = _pick_random_indices(candidate_sam_points.size(), 4)
	for idx: int in sam_indices:
		var pos: Vector3 = candidate_sam_points[idx]
		var sam: Node3D = _instantiate_or_placeholder(turret_sam_scene, "TurretSAM", pos, enemies_container)
		result["sams"].append(sam)
	
	# 3. 2 Blindados Leves IFV
	var tank_indices: Array[int] = _pick_random_indices(candidate_light_tank_points.size(), 2)
	for idx: int in tank_indices:
		var pos: Vector3 = candidate_light_tank_points[idx]
		var tank: Node3D = _instantiate_or_placeholder(light_tank_scene, "LightTank_IFV", pos, enemies_container)
		var tank_ai: EnemyAIController = tank.get_node_or_null("EnemyAIController") as EnemyAIController
		if tank_ai != null:
			tank_ai.patrol_waypoints = [
				pos + Vector3(18.0, 0.0, 0.0),
				pos + Vector3(0.0, 0.0, 18.0),
				pos + Vector3(-18.0, 0.0, 0.0),
				pos + Vector3(0.0, 0.0, -18.0)
			]
		result["tanks"].append(tank)
	
	# 4. 2 Lanchas de Patrulha
	var boat_indices: Array[int] = _pick_random_indices(candidate_patrol_boat_points.size(), 2)
	for idx: int in boat_indices:
		var pos: Vector3 = candidate_patrol_boat_points[idx]
		var boat: Node3D = _instantiate_or_placeholder(patrol_boat_scene, "PatrolBoat", pos, enemies_container)
		var boat_ai: EnemyAIController = boat.get_node_or_null("EnemyAIController") as EnemyAIController
		if boat_ai != null:
			boat_ai.patrol_waypoints = [
				pos + Vector3(30.0, 0.0, 0.0),
				pos + Vector3(0.0, 0.0, 20.0),
				pos + Vector3(-30.0, 0.0, 0.0),
				pos + Vector3(0.0, 0.0, -20.0)
			]
		result["boats"].append(boat)
	
	# 5. 2 Caixas de Dados entre 4 pontos
	var crate_indices: Array[int] = _pick_random_indices(candidate_data_crate_points.size(), 2)
	for idx: int in crate_indices:
		var pos: Vector3 = candidate_data_crate_points[idx]
		var crate: Node3D = _instantiate_or_placeholder(data_crate_scene, "DataCrate", pos, crates_container)
		result["crates"].append(crate)
	
	return result


## Dispara uma onda de reforcos reativos (2 HunterDrones + 1 MercenarySquad) convergindo no alvo.
##
## Args:
##     origin_pos (Vector3): Ponto de referencia do evento (abrigo ou crate violado).
##
## Returns:
##     Array[Node3D]: Lista de instancias geradas na onda reativa.
##
## Raises:
##     Nenhuma excecao levantada.
func trigger_reactive_wave(origin_pos: Vector3) -> Array[Node3D]:
	var dispatched: Array[Node3D] = []
	
	var center: Vector3 = origin_pos
	if player_ref != null and is_instance_valid(player_ref):
		center = player_ref.global_position
	
	# 2 HunterDrones aereos surgem no perimetro a 60m convergindo
	var angle_a: float = randf() * TAU
	var angle_b: float = angle_a + PI * 0.5
	
	var drone_a_pos: Vector3 = center + Vector3(cos(angle_a), 0.0, sin(angle_a)) * DRONE_REACTIVE_RADIUS
	drone_a_pos.y = 4.0
	var drone_a: Node3D = _instantiate_or_placeholder(hunter_drone_scene, "HunterDrone", drone_a_pos, enemies_container)
	dispatched.append(drone_a)
	
	var drone_b_pos: Vector3 = center + Vector3(cos(angle_b), 0.0, sin(angle_b)) * DRONE_REACTIVE_RADIUS
	drone_b_pos.y = 4.0
	var drone_b: Node3D = _instantiate_or_placeholder(hunter_drone_scene, "HunterDrone", drone_b_pos, enemies_container)
	dispatched.append(drone_b)
	
	# 1 MercenarySquad terrestre avancando
	var merc_angle: float = angle_a + PI
	var merc_pos: Vector3 = center + Vector3(cos(merc_angle), 0.0, sin(merc_angle)) * 30.0
	merc_pos.y = 0.0
	var merc: Node3D = _instantiate_or_placeholder(mercenary_squad_scene, "MercenarySquad", merc_pos, enemies_container)
	var reactive_merc_ai: EnemyAIController = merc.get_node_or_null("EnemyAIController") as EnemyAIController
	if reactive_merc_ai != null:
		reactive_merc_ai.patrol_waypoints = [
			origin_pos,
			origin_pos + Vector3(6.0, 0.0, 6.0),
			origin_pos + Vector3(-6.0, 0.0, 6.0),
			origin_pos + Vector3(-6.0, 0.0, -6.0)
		]
	dispatched.append(merc)
	
	reactive_wave_dispatched.emit(origin_pos, dispatched)
	return dispatched


## Callback acionado pelo EventBus ao destruir um abrigo.
##
## Args:
##     shelter_position (Vector3): Coordenadas onde o abrigo colapsou.
##     survivor_count (int): Quantidade de civis liberados no solo.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_shelter_destroyed(shelter_position: Vector3, _survivor_count: int) -> void:
	trigger_reactive_wave(shelter_position)


## Callback acionado pelo EventBus ao abrir um crate de dados.
##
## Args:
##     _available_boons (Array): Lista de boons sorteados.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _on_data_crate_opened(_available_boons: Array) -> void:
	var target_pos: Vector3 = global_position
	if player_ref != null and is_instance_valid(player_ref):
		target_pos = player_ref.global_position
	trigger_reactive_wave(target_pos)


## Instancia uma PackedScene ou gera um nó placeholder configurado com grupos adequados.
##
## Args:
##     scene (PackedScene): Cena a instanciar (opcional).
##     fallback_name (String): Nome base do nó gerado.
##     pos (Vector3): Coordenadas espaciais de alocacao.
##     parent_container (Node3D): Contêiner pai opcional.
##
## Returns:
##     Node3D: Instancia alocada na arvore.
##
## Raises:
##     Nenhuma excecao levantada.
func _instantiate_or_placeholder(
	scene: PackedScene,
	fallback_name: String,
	pos: Vector3,
	parent_container: Node3D
) -> Node3D:
	var instance: Node3D
	if scene != null:
		instance = scene.instantiate() as Node3D
	else:
		instance = Node3D.new()
		instance.name = fallback_name
		instance.add_to_group("enemies")
	
	instance.position = pos
	
	var target_parent: Node = parent_container if parent_container != null else self
	target_parent.add_child(instance)
	return instance


## Sorteia N indices unicos sem repeticao de uma colecao de tamanho total.
##
## Args:
##     total_size (int): Quantidade total de elementos.
##     count (int): Quantidade de indices distintos a selecionar.
##
## Returns:
##     Array[int]: Lista de indices sorteados.
##
## Raises:
##     Nenhuma excecao levantada.
func _pick_random_indices(total_size: int, count: int) -> Array[int]:
	var indices: Array[int] = []
	for i in range(total_size):
		indices.append(i)
	indices.shuffle()
	
	var picked: Array[int] = []
	var limit: int = mini(count, indices.size())
	for i in range(limit):
		picked.append(indices[i])
	return picked


## Carrega cenas canonicas disponiveis nos diretorios do projeto.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _load_default_scenes() -> void:
	if shelter_scene == null and ResourceLoader.exists("res://scenes/entities/npcs/rescue_shelter.tscn"):
		shelter_scene = ResourceLoader.load("res://scenes/entities/npcs/rescue_shelter.tscn")
	
	if data_crate_scene == null and ResourceLoader.exists("res://scenes/roguelite/data_crate.tscn"):
		data_crate_scene = ResourceLoader.load("res://scenes/roguelite/data_crate.tscn")
	
	if mercenary_squad_scene == null and ResourceLoader.exists("res://scenes/entities/enemies/mercenary_squad.tscn"):
		mercenary_squad_scene = ResourceLoader.load("res://scenes/entities/enemies/mercenary_squad.tscn")
		
	if turret_sam_scene == null and ResourceLoader.exists("res://scenes/entities/enemies/turret_sam.tscn"):
		turret_sam_scene = ResourceLoader.load("res://scenes/entities/enemies/turret_sam.tscn")
		
	if light_tank_scene == null and ResourceLoader.exists("res://scenes/entities/enemies/light_tank_ifv.tscn"):
		light_tank_scene = ResourceLoader.load("res://scenes/entities/enemies/light_tank_ifv.tscn")
		
	if patrol_boat_scene == null and ResourceLoader.exists("res://scenes/entities/enemies/patrol_boat.tscn"):
		patrol_boat_scene = ResourceLoader.load("res://scenes/entities/enemies/patrol_boat.tscn")
		
	if hunter_drone_scene == null and ResourceLoader.exists("res://scenes/entities/enemies/hunter_drone.tscn"):
		hunter_drone_scene = ResourceLoader.load("res://scenes/entities/enemies/hunter_drone.tscn")


## Coleta pontos de spawn a partir de filhos marcadores caso presentes no grafo.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _collect_marker_spawn_points() -> void:
	var shelter_group: Node = get_node_or_null("ShelterSpawnPoints")
	if shelter_group != null and shelter_group.get_child_count() > 0:
		candidate_shelter_points.clear()
		for child: Node in shelter_group.get_children():
			if child is Node3D:
				candidate_shelter_points.append((child as Node3D).position)
				
	var sam_group: Node = get_node_or_null("SAMSpawnPoints")
	if sam_group != null and sam_group.get_child_count() > 0:
		candidate_sam_points.clear()
		for child: Node in sam_group.get_children():
			if child is Node3D:
				candidate_sam_points.append((child as Node3D).position)
				
	var crate_group: Node = get_node_or_null("DataCrateSpawnPoints")
	if crate_group != null and crate_group.get_child_count() > 0:
		candidate_data_crate_points.clear()
		for child: Node in crate_group.get_children():
			if child is Node3D:
				candidate_data_crate_points.append((child as Node3D).position)
