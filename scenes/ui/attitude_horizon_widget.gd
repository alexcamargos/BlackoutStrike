## Widget de Horizonte Artificial e Atitude de Voo militar.
##
## Reflete o rolamento cosmético e a arfagem do helicóptero do jogador
## sobre uma escala militar semicircular com asas de referência.
class_name AttitudeHorizonWidget
extends Control

var _tracked_player: Node3D = null


func _process(_delta: float) -> void:
	if _tracked_player == null or not is_instance_valid(_tracked_player):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_tracked_player = players[0] as Node3D
	
	if material is ShaderMaterial:
		var smat: ShaderMaterial = material as ShaderMaterial
		if _tracked_player != null and is_instance_valid(_tracked_player):
			var rot_z: float = _tracked_player.rotation.z
			var rot_x: float = _tracked_player.rotation.x
			smat.set_shader_parameter("roll_angle", -rot_z)
			smat.set_shader_parameter("pitch_offset", clampf(rot_x * 1.5, -0.8, 0.8))
		else:
			smat.set_shader_parameter("roll_angle", 0.0)
			smat.set_shader_parameter("pitch_offset", 0.0)
