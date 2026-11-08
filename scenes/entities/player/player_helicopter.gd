## Entidade principal da aeronave R-9X Mohawk III controlada pelo jogador.
##
## Orquestra os componentes de movimentacao inercial, consumo de combustivel,
## integridade de blindagem, rotinas de autorrotacao e notificacoes do EventBus.
class_name PlayerHelicopter
extends CharacterBody3D

## Duracao total da sequencia de queda desgovernada por pane seca (segundos).
const AUTOROTATION_DURATION: float = 3.0

## Referencias aos subsistemas da entidade.
@onready var flight_controller: FlightMovementController = $FlightMovementController
@onready var health_component: HealthComponent = $HealthComponent
@onready var fuel_component: FuelComponent = $FuelComponent
@onready var mesh_container: Node3D = $HelicopterMeshContainer
@onready var main_rotor: Node3D = $HelicopterMeshContainer/MainRotor
@onready var tail_rotor: Node3D = $HelicopterMeshContainer/TailRotor

## Flags e rastreadores de estado da aeronave.
var is_autorotating: bool = false
var autorotation_timer: float = 0.0
var previous_horizontal_velocity: Vector3 = Vector3.ZERO
var death_cause: String = "structural_failure"

## Coordenada de mira no plano horizontal de voo (modo mira com cursor do mouse).
var aim_target_world: Vector3 = Vector3.ZERO
var has_aim_target: bool = false


## Inicializa a entidade conectando sinais de subsistemas e publicando telemetria inicial.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	if fuel_component != null:
		fuel_component.fuel_depleted.connect(_on_fuel_depleted)
		fuel_component.fuel_changed.connect(_on_fuel_changed)
	
	if health_component != null:
		health_component.entity_destroyed.connect(_on_entity_destroyed)
		health_component.health_changed.connect(_on_health_changed)
	
	# Inicializa notificacoes de telemetria no EventBus global se acessivel
	if EventBus != null:
		if fuel_component != null:
			EventBus.player_fuel_changed.emit(fuel_component.current_fuel, fuel_component.max_fuel)
		if health_component != null:
			EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)


## Executa o ciclo de simulacao fisica, alternando entre voo normal e autorrotacao.
##
## Args:
##     delta (float): Intervalo de tempo fisico em segundos.
##
## Returns:
##     void
func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return
	
	if is_autorotating:
		_process_autorotation(delta)
		return
	
	if health_component != null and health_component.is_destroyed():
		return
	
	_process_flight_controls(delta)


## Configura o ponto focal de mira da aeronave no plano 3D de combate.
##
## Args:
##     target (Vector3): Ponto alvo projetado no espaco tridimensional.
##
## Returns:
##     void
func set_aim_target(target: Vector3) -> void:
	aim_target_world = target
	has_aim_target = true


## Remove o alvo fixo de mira, restaurando o alinhamento da proa com o vetor de deslocamento.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func clear_aim_target() -> void:
	has_aim_target = false


## Projeta o cursor da tela sobre o plano horizontal de cruzeiro e atualiza a mira.
##
## Args:
##     camera (Camera3D): Camera ativa da cena.
##     mouse_pos (Vector2): Coordenadas do mouse na tela.
##     plane_y (float): Cota de altitude do plano de interceptacao (padrao 4.0 m).
##
## Returns:
##     void
func update_mouse_aim(camera: Camera3D, mouse_pos: Vector2, plane_y: float = 4.0) -> void:
	if camera == null:
		return
	var plane: Plane = Plane(Vector3.UP, -plane_y)
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_pos)
	var hit: Variant = plane.intersects_ray(ray_origin, ray_normal)
	if hit != null:
		set_aim_target(hit as Vector3)


## Processa comandos de voo, consumo de combustivel e cinemática inercial.
##
## Args:
##     delta (float): Intervalo de tempo fisico em segundos.
##
## Returns:
##     void
func _process_flight_controls(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_west", "move_east", "move_north", "move_south")
	var is_descending: bool = Input.is_action_pressed("altitude_descend")
	
	# Gerenciamento de queima de combustivel
	if fuel_component != null and not fuel_component.is_empty():
		if input_dir.length_squared() > 0.01:
			fuel_component.consume_active(delta)
		else:
			fuel_component.consume_passive(delta)
	
	# Calculo de aceleracao linear para inclinacao cosmética no espaco local
	var current_h_vel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var global_accel: Vector3 = (current_h_vel - previous_horizontal_velocity) / delta
	previous_horizontal_velocity = current_h_vel
	
	if flight_controller != null:
		velocity = flight_controller.compute_velocity(velocity, input_dir, is_descending, global_position.y, delta)
	
	move_and_slide()
	
	# Orientacao horizontal (Yaw): prioriza ponto de mira do cursor; caso ausente, usa vetor de movimento
	var target_yaw: float = rotation.y
	var should_rotate: bool = false
	if has_aim_target:
		var aim_dir: Vector3 = aim_target_world - global_position
		aim_dir.y = 0.0
		if aim_dir.length_squared() > 0.04:
			target_yaw = atan2(-aim_dir.x, -aim_dir.z)
			should_rotate = true
	elif input_dir.length_squared() > 0.01:
		target_yaw = atan2(-input_dir.x, -input_dir.y)
		should_rotate = true
	
	if should_rotate and flight_controller != null:
		rotation.y = rotate_toward(rotation.y, target_yaw, flight_controller.yaw_turn_speed * delta)
	
	# Inclinacao cosmética dinâmica da malha (Roll e Pitch) calculada no espaco local
	if mesh_container != null and flight_controller != null:
		var local_accel: Vector3 = global_transform.basis.inverse() * global_accel
		var target_tilt: Vector3 = flight_controller.compute_cosmetic_tilt(local_accel)
		mesh_container.rotation.x = lerpf(mesh_container.rotation.x, target_tilt.x, 10.0 * delta)
		mesh_container.rotation.z = lerpf(mesh_container.rotation.z, target_tilt.z, 10.0 * delta)
	
	# Rotacao continua das helices
	if main_rotor != null:
		main_rotor.rotate_y(35.0 * delta)
	if tail_rotor != null:
		tail_rotor.rotate_x(45.0 * delta)


## Processa a sequencia incontrolavel de queda em autorrotacao apos pane seca.
##
## Args:
##     delta (float): Intervalo de tempo fisico em segundos.
##
## Returns:
##     void
func _process_autorotation(delta: float) -> void:
	autorotation_timer += delta
	
	# Giro violento da fuselagem em torno do proprio eixo Y
	if mesh_container != null:
		mesh_container.rotate_y(14.0 * delta)
	
	# Desaceleracao horizontal e perda constante de altitude
	velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
	velocity.y = - (4.0 / AUTOROTATION_DURATION)
	
	move_and_slide()
	
	if main_rotor != null:
		main_rotor.rotate_y(10.0 * delta)
	
	if autorotation_timer >= AUTOROTATION_DURATION:
		is_autorotating = false
		death_cause = "fuel_exhaustion"
		if health_component != null:
			health_component.take_damage(health_component.max_health)


## Callback acionado pelo sinal de pane seca do componente de combustivel.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_fuel_depleted() -> void:
	if not is_autorotating and (health_component == null or not health_component.is_destroyed()):
		is_autorotating = true
		autorotation_timer = 0.0
		if EventBus != null:
			EventBus.player_fuel_depleted.emit()


## Callback acionado pela atualizacao de combustivel.
##
## Args:
##     current (float): Quantidade atual de combustivel.
##     max_fuel (float): Capacidade maxima do tanque.
##
## Returns:
##     void
func _on_fuel_changed(current: float, max_fuel: float) -> void:
	if EventBus != null:
		EventBus.player_fuel_changed.emit(current, max_fuel)


## Callback acionado pela variacao de pontos de vida.
##
## Args:
##     current (float): Integridade atual da blindagem.
##     max_hp (float): Integridade maxima nominal.
##
## Returns:
##     void
func _on_health_changed(current: float, max_hp: float) -> void:
	if EventBus != null:
		EventBus.player_health_changed.emit(current, max_hp)


## Callback acionado pela destruicao estrutural da aeronave.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_entity_destroyed() -> void:
	set_physics_process(false)
	if EventBus != null:
		EventBus.player_died.emit(death_cause)
