## Malha de oceano infinita com reposicionamento centrado na visao da camera ou jogador.
##
## Mantem a cota Y estritamente em 0.0 (nivel do mar) enquanto acompanha o deslocamento horizontal
## no plano XZ em todo o mapa de 2.500 x 2.500m sem gerar custos excessivos de vertices ou draw calls.
class_name FollowCameraOcean
extends MeshInstance3D

## Referencia opcional ao nó focal da navegacao (jogador ou camera).
@export var target_node: Node3D = null


## Atualiza as coordenadas horizontais para acompanhar o ponto de vista a cada quadro.
##
## Args:
##     _delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func _process(_delta: float) -> void:
	step()


## Executa o reposicionamento da malha de agua (suporta simulacao direta).
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func step() -> void:
	var target_x: float = global_position.x
	var target_z: float = global_position.z
	
	if target_node != null and is_instance_valid(target_node):
		target_x = target_node.global_position.x
		target_z = target_node.global_position.z
	else:
		var cam: Camera3D = null
		var vp: Viewport = get_viewport()
		if vp != null:
			cam = vp.get_camera_3d()
		if cam != null and is_instance_valid(cam):
			target_x = cam.global_position.x
			target_z = cam.global_position.z
	
	global_position = Vector3(target_x, 0.0, target_z)
