## Area sensorial de deteccao de resgate e controle do anel holografico.
##
## Monitora civis abaixo da aeronave em cota de pairamento (Y <= 1.2m), avalia
## supressao por inimigos terrestres proximos (<= 10.0m) e orquestra o embarque.
class_name RescueSensorArea
extends Area3D

## Sinal emitido quando a contagem de tempo de embarque e alterada.
signal boarding_progress_changed(progress: float)

## Cota maxima de altitude do helicoptero para habilitar a operacao de resgate.
@export var max_rescue_altitude: float = 1.2

## Velocidade horizontal maxima permitida para manter o anel de resgate ativo.
@export var max_rescue_speed: float = 4.0

## Raio do perimetro ao redor do civil inspecionado contra ameacas terrestres.
@export var suppression_radius: float = 10.0

## Tempo necessario de permanencia estavel sem ameacas para embarcar 1 civil.
@export var boarding_duration: float = 2.0

## Referencia ao componente de carga do helicoptero.
@export var cargo_component: CargoComponent

## Referencia a malha visual do anel holografico projetado no solo.
@export var rescue_ring_mesh: MeshInstance3D

## Material do shader aplicado ao anel holografico.
var ring_material: ShaderMaterial

## Alvo civil atualmente sob o foco de embarque.
var current_target_civilian: Civilian = null

## Temporizador acumulado da acao de embarque em segundos.
var boarding_timer: float = 0.0

## Flag que indica se a operacao esta suprimida por inimigos no perimetro.
var is_suppressed: bool = false

## Lista interna de civis atualmente na area de cobertura do sensor.
var _detected_civilians: Array[Civilian] = []


## Inicializa o sensor, mascaras de colisao, malha do anel e conexoes de eventos.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	# Camada 7 = Civilians (bitmask 64)
	collision_layer = 0
	collision_mask = 64
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if cargo_component == null:
		var parent_node: Node = get_parent()
		if parent_node != null:
			cargo_component = parent_node.get_node_or_null("CargoComponent") as CargoComponent
	
	_setup_rescue_ring_mesh()


## Cria ou vincula a malha visual do anel holografico com o shader especializado.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _setup_rescue_ring_mesh() -> void:
	if rescue_ring_mesh == null:
		rescue_ring_mesh = get_node_or_null("RescueRingMesh") as MeshInstance3D
	
	if rescue_ring_mesh == null:
		rescue_ring_mesh = MeshInstance3D.new()
		rescue_ring_mesh.name = "RescueRingMesh"
		
		var plane_mesh: PlaneMesh = PlaneMesh.new()
		plane_mesh.size = Vector2(7.0, 7.0) # Diametro compativel com o raio de 3.5m
		rescue_ring_mesh.mesh = plane_mesh
		
		var shader_res: Shader = load("res://assets/shaders/rescue_ring.gdshader") as Shader
		if shader_res != null:
			ring_material = ShaderMaterial.new()
			ring_material.shader = shader_res
			rescue_ring_mesh.material_override = ring_material
		
		add_child(rescue_ring_mesh)
	else:
		if rescue_ring_mesh.material_override is ShaderMaterial:
			ring_material = rescue_ring_mesh.material_override as ShaderMaterial
	
	if rescue_ring_mesh != null:
		rescue_ring_mesh.visible = false


## Processa a verificacao ciclica de voo, inimigos, supressao e embarque.
##
## Args:
##     delta (float): Intervalo do quadro de fisica em segundos.
##
## Returns:
##     void
func _physics_process(delta: float) -> void:
	step(delta)


## Executa uma etapa de avaliacao de resgate (suporta acionamento manual em testes).
##
## Args:
##     delta (float): Intervalo de tempo do ciclo em segundos.
##
## Returns:
##     void
func step(delta: float) -> void:
	_cleanup_dead_civilians()
	
	var helicopter: CharacterBody3D = get_parent() as CharacterBody3D
	var current_altitude: float = global_position.y
	var horizontal_speed: float = 0.0
	
	if helicopter != null:
		current_altitude = helicopter.global_position.y
		var horizontal_vel: Vector2 = Vector2(helicopter.velocity.x, helicopter.velocity.z)
		horizontal_speed = horizontal_vel.length()
	
	var is_hover_valid: bool = current_altitude <= max_rescue_altitude and horizontal_speed <= max_rescue_speed
	
	if not is_hover_valid:
		_reset_rescue_progress()
		return
	
	if cargo_component != null and cargo_component.is_full():
		_reset_rescue_progress()
		return
	
	if current_target_civilian == null:
		current_target_civilian = _find_closest_civilian()
	
	if current_target_civilian == null:
		_reset_rescue_progress()
		return
	
	_update_ring_transform()
	
	var suppressed_now: bool = is_perimeter_suppressed(current_target_civilian.global_position)
	_set_suppression_state(suppressed_now)
	
	if is_suppressed:
		_update_ring_shader_params()
		return
	
	boarding_timer += delta
	var progress: float = clampf(boarding_timer / boarding_duration, 0.0, 1.0)
	boarding_progress_changed.emit(progress)
	_update_ring_shader_params()
	
	if boarding_timer >= boarding_duration:
		_execute_boarding()


## Verifica se existem inimigos terrestres vivos a 10.0m ou menos do civil.
##
## Args:
##     civilian_pos (Vector3): Coordenadas globais do civil.
##
## Returns:
##     bool: True se houver ameaca no perimetro; False se a area for segura.
func is_perimeter_suppressed(civilian_pos: Vector3) -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	
	var enemies: Array[Node] = tree.get_nodes_in_group("enemies")
	for enemy_node in enemies:
		var enemy_3d: Node3D = enemy_node as Node3D
		if enemy_3d == null or enemy_3d.is_queued_for_deletion():
			continue
		
		# Verifica se a entidade esta viva
		if enemy_node.has_node("HealthComponent"):
			var hc: HealthComponent = enemy_node.get_node("HealthComponent") as HealthComponent
			if hc != null and hc.is_destroyed():
				continue
		
		# Ignora drones puramente aereos (Camada 4 = bitmask 8 / group "air_enemies")
		if enemy_node.is_in_group("air_enemies"):
			continue
		if enemy_3d is CollisionObject3D:
			var col: CollisionObject3D = enemy_3d as CollisionObject3D
			if col.collision_layer == 8: # Apenas Enemies_Air
				continue
		
		var dist: float = civilian_pos.distance_to(enemy_3d.global_position)
		if dist <= suppression_radius:
			return true
	
	return false


## Retorna o progresso normalizado atual de embarque (0.0 a 1.0).
##
## Args:
##     Nenhum.
##
## Returns:
##     float: Valor entre 0.0 e 1.0.
func get_boarding_progress() -> float:
	if boarding_duration <= 0.0:
		return 0.0
	return clampf(boarding_timer / boarding_duration, 0.0, 1.0)


## Conclui o ciclo de embarque, inserindo o civil na cabine e liberando o alvo.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _execute_boarding() -> void:
	if current_target_civilian == null:
		return
	
	if cargo_component != null:
		var boarded: bool = cargo_component.try_board_passenger()
		if boarded:
			current_target_civilian.rescue()
	else:
		current_target_civilian.rescue()
	
	current_target_civilian = null
	boarding_timer = 0.0
	boarding_progress_changed.emit(0.0)
	_update_ring_shader_params()


## Posiciona a malha do anel holografico sobre a projecao do solo sob o civil.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _update_ring_transform() -> void:
	if rescue_ring_mesh == null or current_target_civilian == null:
		return
	
	rescue_ring_mesh.visible = true
	rescue_ring_mesh.global_position = Vector3(
		current_target_civilian.global_position.x,
		0.05,
		current_target_civilian.global_position.z
	)


## Atualiza as variaveis uniformes do ShaderMaterial do anel holografico.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _update_ring_shader_params() -> void:
	if ring_material == null and rescue_ring_mesh != null:
		if rescue_ring_mesh.material_override is ShaderMaterial:
			ring_material = rescue_ring_mesh.material_override as ShaderMaterial
	
	if ring_material != null:
		ring_material.set_shader_parameter("is_suppressed", is_suppressed)
		ring_material.set_shader_parameter("progress", get_boarding_progress())


## Altera o estado de supressao e notifica o barramento de eventos se houver mudanca.
##
## Args:
##     new_state (bool): Novo estado de supressao avaliado.
##
## Returns:
##     void
func _set_suppression_state(new_state: bool) -> void:
	if is_suppressed != new_state:
		is_suppressed = new_state
		if EventBus != null:
			EventBus.rescue_zone_suppressed.emit(is_suppressed)


## Reseta os cronometros de resgate e oculta o anel visual quando o voo e interrompido.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _reset_rescue_progress() -> void:
	boarding_timer = 0.0
	_set_suppression_state(false)
	
	if rescue_ring_mesh != null:
		rescue_ring_mesh.visible = false
	
	_update_ring_shader_params()


## Identifica o civil mais proximo no raio de deteccao do sensor.
##
## Args:
##     Nenhum.
##
## Returns:
##     Civilian: Instancia valida mais proxima ou null.
func _find_closest_civilian() -> Civilian:
	var closest: Civilian = null
	var min_dist: float = INF
	
	for civ in _detected_civilians:
		if civ == null or civ.is_queued_for_deletion() or civ.is_dead:
			continue
		var dist: float = global_position.distance_to(civ.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = civ
	
	return closest


## Remove referencias a civis que foram destruidos ou resgatados.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _cleanup_dead_civilians() -> void:
	var valid_civilians: Array[Civilian] = []
	for civ in _detected_civilians:
		if is_instance_valid(civ) and not civ.is_queued_for_deletion() and not civ.is_dead:
			valid_civilians.append(civ)
	_detected_civilians = valid_civilians
	
	if current_target_civilian != null:
		if not is_instance_valid(current_target_civilian) or current_target_civilian.is_dead or current_target_civilian.is_queued_for_deletion():
			current_target_civilian = null


## Manipulador disparado ao detectar um corpo fisico adentrando o volume do sensor.
##
## Args:
##     body (Node3D): Corpo colidido com a area.
##
## Returns:
##     void
func _on_body_entered(body: Node3D) -> void:
	if body is Civilian and not _detected_civilians.has(body):
		_detected_civilians.append(body as Civilian)


## Manipulador disparado ao detectar a saida de um corpo fisico do volume do sensor.
##
## Args:
##     body (Node3D): Corpo que deixou a area.
##
## Returns:
##     void
func _on_body_exited(body: Node3D) -> void:
	if body is Civilian:
		_detected_civilians.erase(body)
		if current_target_civilian == body:
			current_target_civilian = null
