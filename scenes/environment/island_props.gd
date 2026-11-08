@tool
## Gerenciador de decoracao cenica e escala para o Atol de Midway.
##
## Instancia em lote palmeiras litoraneas, conteineres logisticos da Aetheris
## e guindastes portuarios utilizando MultiMeshInstance3D para zero draw calls adicionais.
class_name IslandProps
extends Node3D

## Referencias aos nos de MultiMeshInstance3D na arvore da cena.
@export var palms_instance: MultiMeshInstance3D
@export var containers_instance: MultiMeshInstance3D
@export var cranes_instance: MultiMeshInstance3D

## Listas internas de posicoes das instancias para telemetria e checagem de colisao.
var _palm_positions: Array[Vector3] = []
var _container_positions: Array[Vector3] = []
var _crane_positions: Array[Vector3] = []


## Inicializa a populacao de malhas em lote ao ingressar na arvore de cena.
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
	if palms_instance != null and palms_instance.multimesh == null:
		_setup_palms()
	
	if containers_instance != null and containers_instance.multimesh == null:
		_setup_containers()
	
	if cranes_instance != null and cranes_instance.multimesh == null:
		_setup_cranes()


## Retorna o numero de palmeiras ativas no cenario.
##
## Args:
##     Nenhum.
##
## Returns:
##     int: Quantidade de instancias de palmeiras.
##
## Raises:
##     Nenhuma excecao levantada.
func get_palm_count() -> int:
	if palms_instance != null and palms_instance.multimesh != null:
		return palms_instance.multimesh.instance_count
	return _palm_positions.size()


## Retorna o numero de conteineres logisticos no cenario.
##
## Args:
##     Nenhum.
##
## Returns:
##     int: Quantidade de instancias de conteineres.
##
## Raises:
##     Nenhuma excecao levantada.
func get_container_count() -> int:
	if containers_instance != null and containers_instance.multimesh != null:
		return containers_instance.multimesh.instance_count
	return _container_positions.size()


## Retorna o numero de guindastes portuarios no cenario.
##
## Args:
##     Nenhum.
##
## Returns:
##     int: Quantidade de instancias de guindastes.
##
## Raises:
##     Nenhuma excecao levantada.
func get_crane_count() -> int:
	if cranes_instance != null and cranes_instance.multimesh != null:
		return cranes_instance.multimesh.instance_count
	return _crane_positions.size()


## Verifica se uma coordenada 3D esta dentro de um raio de proximidade de qualquer prop.
##
## Args:
##     point (Vector3): Ponto no espaco global a ser checado.
##     threshold (float): Raio limite de distancia.
##
## Returns:
##     bool: True se o ponto estiver a menos de threshold de algum prop.
##
## Raises:
##     Nenhuma excecao levantada.
func is_point_near_prop(point: Vector3, threshold: float) -> bool:
	var sq_threshold: float = threshold * threshold
	for pos in _palm_positions:
		if pos.distance_squared_to(point) <= sq_threshold:
			return true
	for pos in _container_positions:
		if pos.distance_squared_to(point) <= sq_threshold:
			return true
	for pos in _crane_positions:
		if pos.distance_squared_to(point) <= sq_threshold:
			return true
	return false


## Constrói a malha combinada de uma palmeira (tronco e folhas).
##
## Args:
##     Nenhum.
##
## Returns:
##     Mesh: Recurso de malha com materiais atribuidos.
##
## Raises:
##     Nenhuma excecao levantada.
func _build_palm_mesh() -> Mesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var trunk_mat: StandardMaterial3D = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.44, 0.30, 0.18, 1.0)
	trunk_mat.roughness = 0.9
	st.set_material(trunk_mat)
	
	# Tronco piramidal/cilindrico estilizado
	var radius_base: float = 0.22
	var radius_top: float = 0.14
	var height: float = 3.6
	var segments: int = 6
	
	for i in range(segments):
		var a1: float = (float(i) / float(segments)) * TAU
		var a2: float = (float(i + 1) / float(segments)) * TAU
		
		var b1: Vector3 = Vector3(cos(a1) * radius_base, 0.0, sin(a1) * radius_base)
		var b2: Vector3 = Vector3(cos(a2) * radius_base, 0.0, sin(a2) * radius_base)
		var t1: Vector3 = Vector3(cos(a1) * radius_top, height, sin(a1) * radius_top)
		var t2: Vector3 = Vector3(cos(a2) * radius_top, height, sin(a2) * radius_top)
		
		st.set_normal((b1 + t1).normalized())
		st.add_vertex(b1)
		st.set_normal((t1).normalized())
		st.add_vertex(t1)
		st.set_normal((b2 + t2).normalized())
		st.add_vertex(b2)
		
		st.set_normal((b2 + t2).normalized())
		st.add_vertex(b2)
		st.set_normal((t1).normalized())
		st.add_vertex(t1)
		st.set_normal((t2).normalized())
		st.add_vertex(t2)
	
	var mesh: ArrayMesh = st.commit()
	
	# Superficie 2: Folhas de palmeira em leque
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaf_mat: StandardMaterial3D = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.18, 0.54, 0.22, 1.0)
	leaf_mat.roughness = 0.75
	st.set_material(leaf_mat)
	
	var leaf_count: int = 8
	var leaf_length: float = 2.1
	var leaf_droop: float = -0.7
	var center_top: Vector3 = Vector3(0.0, height, 0.0)
	
	for i in range(leaf_count):
		var angle: float = (float(i) / float(leaf_count)) * TAU
		var side_angle: float = angle + (PI / float(leaf_count))
		var tip: Vector3 = center_top + Vector3(cos(angle) * leaf_length, leaf_droop, sin(angle) * leaf_length)
		var side: Vector3 = center_top + Vector3(cos(side_angle) * 0.45, -0.15, sin(side_angle) * 0.45)
		
		st.set_normal(Vector3.UP)
		st.add_vertex(center_top)
		st.add_vertex(side)
		st.add_vertex(tip)
		
		# Face oposta para visualizacao bilateral
		st.set_normal(Vector3.DOWN)
		st.add_vertex(center_top)
		st.add_vertex(tip)
		st.add_vertex(side)
	
	mesh = st.commit(mesh)
	return mesh


## Constrói a malha de um conteiner logistico da Aetheris.
##
## Args:
##     Nenhum.
##
## Returns:
##     Mesh: BoxMesh com pintura industrial e material PBR.
##
## Raises:
##     Nenhuma excecao levantada.
func _build_container_mesh() -> Mesh:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(3.2, 1.4, 1.4)
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.35, 0.46, 1.0)
	mat.metallic = 0.45
	mat.roughness = 0.55
	box.material = mat
	return box


## Constrói a malha de um guindaste portuario com braco horizontal e cabine.
##
## Args:
##     Nenhum.
##
## Returns:
##     Mesh: ArrayMesh com pintura industrial amarela/alaranjada.
##
## Raises:
##     Nenhuma excecao levantada.
func _build_crane_mesh() -> Mesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.58, 0.12, 1.0)
	mat.metallic = 0.35
	mat.roughness = 0.5
	st.set_material(mat)
	
	# Torre vertical (altura 9.0m, secao 2.0 x 2.0m)
	_add_box_to_surface(st, Vector3(0.0, 4.5, 0.0), Vector3(2.0, 9.0, 2.0))
	# Braco horizontal de icamento (comprimento 9.0m, secao 1.2 x 1.2m, no topo)
	_add_box_to_surface(st, Vector3(3.5, 9.5, 0.0), Vector3(9.0, 1.2, 1.2))
	# Contrapeso traseiro
	_add_box_to_surface(st, Vector3(-2.0, 9.5, 0.0), Vector3(2.4, 1.8, 1.6))
	# Cabine de controle
	_add_box_to_surface(st, Vector3(1.2, 8.2, 0.9), Vector3(1.4, 1.4, 1.2))
	
	return st.commit()


## Adiciona vertices de um cubo a um SurfaceTool.
##
## Args:
##     st (SurfaceTool): Instancia ativa do gerador de malha.
##     center (Vector3): Centro do cubo no espaco local.
##     size (Vector3): Dimensoes largura, altura e profundidade.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _add_box_to_surface(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var v0: Vector3 = center + Vector3(-h.x, -h.y, -h.z)
	var v1: Vector3 = center + Vector3(h.x, -h.y, -h.z)
	var v2: Vector3 = center + Vector3(h.x, h.y, -h.z)
	var v3: Vector3 = center + Vector3(-h.x, h.y, -h.z)
	var v4: Vector3 = center + Vector3(-h.x, -h.y, h.z)
	var v5: Vector3 = center + Vector3(h.x, -h.y, h.z)
	var v6: Vector3 = center + Vector3(h.x, h.y, h.z)
	var v7: Vector3 = center + Vector3(-h.x, h.y, h.z)
	
	# Frente (+Z)
	_add_quad_to_surface(st, v4, v5, v6, v7, Vector3.BACK)
	# Fundo (-Z)
	_add_quad_to_surface(st, v1, v0, v3, v2, Vector3.FORWARD)
	# Direita (+X)
	_add_quad_to_surface(st, v5, v1, v2, v6, Vector3.RIGHT)
	# Esquerda (-X)
	_add_quad_to_surface(st, v0, v4, v7, v3, Vector3.LEFT)
	# Topo (+Y)
	_add_quad_to_surface(st, v7, v6, v2, v3, Vector3.UP)
	# Base (-Y)
	_add_quad_to_surface(st, v0, v1, v5, v4, Vector3.DOWN)


## Adiciona um poligono quadrilatero composto por dois triangulos.
##
## Args:
##     st (SurfaceTool): SurfaceTool em gravacao.
##     p0 (Vector3): Vertice inferior esquerdo.
##     p1 (Vector3): Vertice inferior direito.
##     p2 (Vector3): Vertice superior direito.
##     p3 (Vector3): Vertice superior esquerdo.
##     normal (Vector3): Vetor normal da face.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _add_quad_to_surface(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, normal: Vector3) -> void:
	st.set_normal(normal)
	st.add_vertex(p0)
	st.add_vertex(p1)
	st.add_vertex(p2)
	
	st.add_vertex(p0)
	st.add_vertex(p2)
	st.add_vertex(p3)


## Configura e popula o MultiMesh de palmeiras litoraneas.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _setup_palms() -> void:
	_palm_positions.clear()
	# Palmeiras distribuidas na faixa costeira e perimetro da ilha
	var base_coords: Array[Vector3] = [
		Vector3(-120.0, 0.3, -40.0),
		Vector3(-118.0, 0.3, -25.0),
		Vector3(-119.0, 0.3, 10.0),
		Vector3(-117.0, 0.3, 35.0),
		Vector3(-115.0, 0.3, 50.0),
		Vector3(118.0, 0.3, -35.0),
		Vector3(120.0, 0.3, -10.0),
		Vector3(119.0, 0.3, 15.0),
		Vector3(116.0, 0.3, 45.0),
		Vector3(114.0, 0.3, 65.0),
		Vector3(-80.0, 0.4, -115.0),
		Vector3(-60.0, 0.4, -118.0),
		Vector3(60.0, 0.4, -118.0),
		Vector3(80.0, 0.4, -115.0),
		Vector3(-25.0, 0.5, -125.0),
		Vector3(25.0, 0.5, -125.0),
		Vector3(-45.0, 0.3, 110.0),
		Vector3(-25.0, 0.3, 115.0),
		Vector3(25.0, 0.3, 115.0),
		Vector3(45.0, 0.3, 110.0),
		Vector3(70.0, 0.3, 105.0),
		Vector3(-70.0, 0.3, 105.0),
		Vector3(-100.0, 0.4, -5.0),
		Vector3(100.0, 0.4, -5.0)
	]
	
	_palm_positions.append_array(base_coords)
	
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = _palm_positions.size()
	mm.mesh = _build_palm_mesh()
	
	for i in range(_palm_positions.size()):
		var pos: Vector3 = _palm_positions[i]
		var angle: float = fposmod(float(i) * 1.618, TAU)
		var scale_var: float = 0.9 + (float(i % 5) * 0.05)
		var basis: Basis = Basis(Vector3.UP, angle).scaled(Vector3(scale_var, scale_var, scale_var))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	
	palms_instance.multimesh = mm


## Configura e popula o MultiMesh de conteineres logisticos.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _setup_containers() -> void:
	_container_positions.clear()
	
	# Pilhas do Deposito Alpha (Setor Oeste, (-75, 15))
	var origin_alpha: Vector3 = Vector3(-78.0, 0.5, 12.0)
	for r in range(3):
		for c in range(3):
			var p: Vector3 = origin_alpha + Vector3(float(r) * 3.6, 0.7, float(c) * 1.8)
			_container_positions.append(p)
			if (r + c) % 2 == 0:
				# Camada superior empilhada
				_container_positions.append(p + Vector3(0.0, 1.4, 0.0))
	
	# Pilhas do Deposito Bravo (Setor Leste, (40, -15))
	var origin_bravo: Vector3 = Vector3(38.0, 0.5, -20.0)
	for r in range(3):
		for c in range(3):
			var p: Vector3 = origin_bravo + Vector3(float(r) * 3.6, 0.7, float(c) * 1.8)
			_container_positions.append(p)
			if (r * c) % 2 == 1:
				_container_positions.append(p + Vector3(0.0, 1.4, 0.0))
	
	# Pilhas do Deposito Charlie (Cais Sul, (-10, 50))
	var origin_charlie: Vector3 = Vector3(-14.0, 0.5, 48.0)
	for r in range(2):
		for c in range(4):
			var p: Vector3 = origin_charlie + Vector3(float(r) * 3.6, 0.7, float(c) * 1.8)
			_container_positions.append(p)
			if c == 1 or c == 2:
				_container_positions.append(p + Vector3(0.0, 1.4, 0.0))
	
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = _container_positions.size()
	mm.mesh = _build_container_mesh()
	
	for i in range(_container_positions.size()):
		var pos: Vector3 = _container_positions[i]
		var basis: Basis = Basis.IDENTITY
		mm.set_instance_transform(i, Transform3D(basis, pos))
	
	containers_instance.multimesh = mm


## Configura e popula o MultiMesh de guindastes portuarios nos ancoradouros.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _setup_cranes() -> void:
	_crane_positions.clear()
	# 4 guindastes estrategicos nos cais norte e sul
	var crane_specs: Array[Dictionary] = [
		{"pos": Vector3(-50.0, 0.5, -122.0), "yaw": PI},
		{"pos": Vector3(50.0, 0.5, -122.0), "yaw": PI},
		{"pos": Vector3(-35.0, 0.5, 105.0), "yaw": 0.0},
		{"pos": Vector3(35.0, 0.5, 105.0), "yaw": 0.0}
	]
	
	for spec in crane_specs:
		_crane_positions.append(spec["pos"])
	
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = _crane_positions.size()
	mm.mesh = _build_crane_mesh()
	
	for i in range(crane_specs.size()):
		var spec: Dictionary = crane_specs[i]
		var pos: Vector3 = spec["pos"]
		var yaw: float = spec["yaw"]
		var basis: Basis = Basis(Vector3.UP, yaw)
		mm.set_instance_transform(i, Transform3D(basis, pos))
	
	cranes_instance.multimesh = mm
