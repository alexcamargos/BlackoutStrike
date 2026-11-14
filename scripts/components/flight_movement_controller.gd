## Controlador matematico de voo inercial, altitude e inclinacao cosmetica.
##
## Modela a aceleracao linear, desaceleracao por arrasto, transicao vertical
## entre cotas de cruzeiro e resgate, e os angulos de inclinacao cosmetica do helicóptero.
class_name FlightMovementController
extends Node

## Obstáculos estáticos do setor de apoio também usam esta camada de consulta.
const CLEARANCE_LAYER: int = 1 << 8
const CLEARANCE_SCAN_HEIGHT: float = 30.0
const CLEARANCE_LOOKAHEAD: float = 2.4
const CLEARANCE_RADIUS: float = 6.0
const CLEARANCE_SAMPLE_SPACING: float = 3.0
const MINIMUM_CLEARANCE: float = 2.0
const CLEARANCE_SCAN_INTERVAL: float = 0.10

## Taxa de aceleracao linear horizontal (m/s^2).
@export var acceleration: float = 18.0

## Velocidade maxima de cruzeiro no plano horizontal (m/s).
@export var max_speed: float = 22.0

## Desaceleracao por arrasto inercial ao cessar o comando de movimento (m/s^2).
@export var drag_deceleration: float = 7.5

## Cota de altitude padrao de cruzeiro e combate (metros).
@export var cruise_altitude: float = 4.0

## Cota de altitude rebaixada para pairado e resgate (metros).
@export var hover_altitude: float = 0.8

## Velocidade de transicao vertical entre cotas de altitude (m/s).
@export var altitude_transition_speed: float = 6.0

## Limite maximo do angulo de inclinacao cosmetica (graus).
@export var max_tilt_deg: float = 22.0

## Velocidade angular para alinhamento horizontal Yaw (radianos/s).
@export var yaw_turn_speed: float = 8.0

var _clearance_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
var _clearance_region: BoxShape3D = BoxShape3D.new()
var _clearance_region_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
var _seconds_to_next_scan: float = 0.0
var _minimum_cruise_y: float = 0.0


## Calcula o vetor de velocidade resultante considerando comandos, arrasto e altitude.
##
## Args:
##     current_velocity (Vector3): Vetor de velocidade atual da aeronave.
##     input_dir (Vector2): Vetor de comando direcional normalizado no plano horizontal (X, Y).
##     is_descending (bool): Flag indicando se a aeronave deve buscar cota de pairado.
##     current_y (float): Posicao atual no eixo Y (altitude).
##     delta (float): Intervalo de tempo do quadro em segundos.
##     minimum_cruise_y (float): Cota mínima calculada para sobrevoar obstáculos no cruzeiro.
##
## Returns:
##     Vector3: Vetor tridimensional de velocidade a ser aplicado no corpo fisico.
func compute_velocity(current_velocity: Vector3, input_dir: Vector2, is_descending: bool, current_y: float,
		delta: float, minimum_cruise_y: float = 0.0) -> Vector3:
	if delta <= 0.0:
		return current_velocity
	
	var current_h_vel: Vector3 = Vector3(current_velocity.x, 0.0, current_velocity.z)
	var new_h_vel: Vector3 = Vector3.ZERO
	
	if input_dir.length_squared() > 0.0001:
		var target_move_dir: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
		var target_h_vel: Vector3 = target_move_dir * max_speed
		new_h_vel = current_h_vel.move_toward(target_h_vel, acceleration * delta)
	else:
		new_h_vel = current_h_vel.move_toward(Vector3.ZERO, drag_deceleration * delta)
	
	var target_y: float = hover_altitude if is_descending else maxf(cruise_altitude, minimum_cruise_y)
	var next_y: float = move_toward(current_y, target_y, altitude_transition_speed * delta)
	var vy: float = (next_y - current_y) / delta
	
	return Vector3(new_h_vel.x, vy, new_h_vel.z)


## Mantém a última cota entre consultas e reinicia a varredura ao voltar da descida.
func update_cruise_clearance(space: PhysicsDirectSpaceState3D, position: Vector3,
		horizontal_velocity: Vector3, is_descending: bool, delta: float) -> float:
	if is_descending:
		_seconds_to_next_scan = 0.0
		return cruise_altitude
	_seconds_to_next_scan -= delta
	if _seconds_to_next_scan <= 0.0:
		_seconds_to_next_scan = CLEARANCE_SCAN_INTERVAL
		_minimum_cruise_y = _scan_cruise_altitude(space, position, horizontal_velocity)
	return _minimum_cruise_y


## Procura o topo mais alto no corredor à frente, usando a direção do deslocamento.
func _scan_cruise_altitude(space: PhysicsDirectSpaceState3D, position: Vector3,
		horizontal_velocity: Vector3) -> float:
	var distance: float = horizontal_velocity.length() * CLEARANCE_LOOKAHEAD
	var heading: Vector3 = horizontal_velocity.normalized() if distance > 0.001 else Vector3.FORWARD
	var corridor_length: float = distance + CLEARANCE_RADIUS * 2.0
	_clearance_region.size = Vector3(CLEARANCE_RADIUS * 2.0, CLEARANCE_SCAN_HEIGHT, corridor_length)
	_clearance_region_query.shape = _clearance_region
	_clearance_region_query.collision_mask = CLEARANCE_LAYER
	var center: Vector3 = position + heading * (distance * 0.5)
	center.y = CLEARANCE_SCAN_HEIGHT * 0.5
	_clearance_region_query.transform = Transform3D(Basis.looking_at(heading), center)
	if space.intersect_shape(_clearance_region_query, 1).is_empty():
		return cruise_altitude

	var side: Vector3 = heading.cross(Vector3.UP)
	var samples: int = ceili(corridor_length / CLEARANCE_SAMPLE_SPACING)
	var clearance: float = cruise_altitude
	_clearance_query.collision_mask = CLEARANCE_LAYER
	for step: int in range(samples + 1):
		var along: float = lerpf(-CLEARANCE_RADIUS, distance + CLEARANCE_RADIUS, float(step) / float(samples))
		var sample_center: Vector3 = position + heading * along
		for lateral: float in [-4.5, -2.25, 0.0, 2.25, 4.5]:
			var point: Vector3 = sample_center + side * lateral
			_clearance_query.from = Vector3(point.x, CLEARANCE_SCAN_HEIGHT, point.z)
			_clearance_query.to = Vector3(point.x, 0.0, point.z)
			var hit: Dictionary = space.intersect_ray(_clearance_query)
			if not hit.is_empty():
				var contact: Vector3 = hit["position"]
				clearance = maxf(clearance, contact.y + MINIMUM_CLEARANCE)
	return clearance


## Calcula os angulos de inclinacao cosmetica (Pitch e Roll) a partir da aceleracao.
##
## Args:
##     acceleration_vector (Vector3): Vetor de aceleracao linear ativa da aeronave.
##
## Returns:
##     Vector3: Vetor com angulos em radianos (Pitch no eixo X, Yaw zerado, Roll no eixo Z).
func compute_cosmetic_tilt(acceleration_vector: Vector3) -> Vector3:
	var safe_accel: float = maxf(acceleration, 0.001)
	var norm_x: float = clampf(acceleration_vector.x / safe_accel, -1.0, 1.0)
	var norm_z: float = clampf(acceleration_vector.z / safe_accel, -1.0, 1.0)
	var max_tilt_rad: float = deg_to_rad(max_tilt_deg)
	
	var pitch: float = norm_z * max_tilt_rad
	var roll: float = -norm_x * max_tilt_rad
	
	return Vector3(pitch, 0.0, roll)
