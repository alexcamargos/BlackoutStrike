## Controlador matematico de voo inercial, altitude e inclinacao cosmetica.
##
## Modela a aceleracao linear, desaceleracao por arrasto, transicao vertical
## entre cotas de cruzeiro e resgate, e os angulos de inclinacao cosmetica do helicóptero.
class_name FlightMovementController
extends Node

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


## Calcula o vetor de velocidade resultante considerando comandos, arrasto e altitude.
##
## Args:
##     current_velocity (Vector3): Vetor de velocidade atual da aeronave.
##     input_dir (Vector2): Vetor de comando direcional normalizado no plano horizontal (X, Y).
##     is_descending (bool): Flag indicando se a aeronave deve buscar cota de pairado.
##     current_y (float): Posicao atual no eixo Y (altitude).
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     Vector3: Vetor tridimensional de velocidade a ser aplicado no corpo fisico.
func compute_velocity(current_velocity: Vector3, input_dir: Vector2, is_descending: bool, current_y: float, delta: float) -> Vector3:
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
	
	var target_y: float = hover_altitude if is_descending else cruise_altitude
	var next_y: float = move_toward(current_y, target_y, altitude_transition_speed * delta)
	var vy: float = (next_y - current_y) / delta
	
	return Vector3(new_h_vel.x, vy, new_h_vel.z)


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
