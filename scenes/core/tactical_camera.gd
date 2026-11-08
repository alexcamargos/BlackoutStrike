## Câmera tática oblíqua estilo shmup moderno (Sky Force).
##
## Inclinação de 68 graus, FOV 36 graus, projeção de perspectiva,
## seguindo o helicóptero do jogador suavemente no plano horizontal.
class_name TacticalCamera
extends Camera3D

@export var target: Node3D
@export var follow_smoothness: float = 8.0
@export var camera_height: float = 38.0
@export var camera_distance_z: float = 15.0
@export var tilt_angle_deg: float = 68.0


func _ready() -> void:
	fov = 36.0
	rotation_degrees = Vector3(-tilt_angle_deg, 0.0, 0.0)
	
	if target == null:
		_find_target()


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_find_target()
		return
	
	var target_pos: Vector3 = target.global_position
	var desired_pos: Vector3 = Vector3(
		target_pos.x,
		target_pos.y + camera_height,
		target_pos.z + camera_distance_z
	)
	
	global_position = global_position.lerp(desired_pos, follow_smoothness * delta)


func _find_target() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var players: Array[Node] = tree.get_nodes_in_group("player")
	if not players.is_empty():
		target = players[0] as Node3D
