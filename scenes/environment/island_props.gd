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
	trunk_mat.albedo_color = Color(0.38, 0.28, 0.18, 1.0)
	trunk_mat.roughness = 0.85
	st.set_material(trunk_mat)
	
	var height: float = 4.2
	var rings: int = 10
	var ring_segments: int = 8
	var curve_dir: Vector2 = Vector2(0.3, 0.1).normalized()
	
	for r in range(rings):
		var t1: float = float(r) / float(rings)
		var t2: float = float(r + 1) / float(rings)
		var y1: float = t1 * height
		var y2: float = t2 * height
		var r1: float = lerpf(0.32, 0.16, t1)
		var r2: float = lerpf(0.32, 0.16, t2)
		var off1: Vector2 = curve_dir * (sin(t1 * PI * 0.6) * 0.5)
		var off2: Vector2 = curve_dir * (sin(t2 * PI * 0.6) * 0.5)
		
		for s in range(ring_segments):
			var a1: float = (float(s) / float(ring_segments)) * TAU
			var a2: float = (float(s + 1) / float(ring_segments)) * TAU
			
			var v1: Vector3 = Vector3(off1.x + cos(a1) * r1, y1, off1.y + sin(a1) * r1)
			var v2: Vector3 = Vector3(off1.x + cos(a2) * r1, y1, off1.y + sin(a2) * r1)
			var v3: Vector3 = Vector3(off2.x + cos(a2) * r2, y2, off2.y + sin(a2) * r2)
			var v4: Vector3 = Vector3(off2.x + cos(a1) * r2, y2, off2.y + sin(a1) * r2)
			
			var norm: Vector3 = (Vector3(cos(a1), 0.1, sin(a1))).normalized()
			st.set_normal(norm)
			st.add_vertex(v1)
			st.add_vertex(v2)
			st.add_vertex(v3)
			
			st.add_vertex(v1)
			st.add_vertex(v3)
			st.add_vertex(v4)
	
	var mesh: ArrayMesh = st.commit()
	
	# Superficie 2: Folhas de palmeira em leque com caimento natural em camadas
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaf_mat: StandardMaterial3D = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.14, 0.45, 0.18, 1.0)
	leaf_mat.roughness = 0.65
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(leaf_mat)
	
	var frond_count: int = 14
	var crown_top: Vector3 = Vector3(curve_dir.x * (sin(PI * 0.6) * 0.5), height, curve_dir.y * (sin(PI * 0.6) * 0.5))
	
	for f in range(frond_count):
		var base_angle: float = (float(f) / float(frond_count)) * TAU
		var layer: float = float(f % 2)
		var length: float = 2.8 + layer * 0.5
		var droop: float = -1.1 - layer * 0.4
		var arch_height: float = 0.5 + layer * 0.3
		
		var steps: int = 4
		var prev_pt: Vector3 = crown_top
		var prev_w: float = 0.15
		
		for step in range(1, steps + 1):
			var st_t: float = float(step) / float(steps)
			var cur_dist: float = st_t * length
			var cur_y: float = crown_top.y + sin(st_t * PI) * arch_height + st_t * droop
			var dir_xz: Vector2 = Vector2(cos(base_angle), sin(base_angle))
			var cur_pt: Vector3 = Vector3(crown_top.x + dir_xz.x * cur_dist, cur_y, crown_top.z + dir_xz.y * cur_dist)
			var cur_w: float = lerpf(0.55, 0.05, st_t)
			
			var side_vec: Vector3 = Vector3(-dir_xz.y, 0.0, dir_xz.x)
			var p1: Vector3 = prev_pt - side_vec * prev_w
			var p2: Vector3 = prev_pt + side_vec * prev_w
			var p3: Vector3 = cur_pt + side_vec * cur_w
			var p4: Vector3 = cur_pt - side_vec * cur_w
			
			st.set_normal(Vector3.UP)
			st.add_vertex(p1)
			st.add_vertex(p2)
			st.add_vertex(p3)
			
			st.add_vertex(p1)
			st.add_vertex(p3)
			st.add_vertex(p4)
			
			prev_pt = cur_pt
			prev_w = cur_w
	
	mesh = st.commit(mesh)
	return mesh


## Constrói a malha de um conteiner logistico da Aetheris a partir de ativo 3D PBR.
##
## Args:
##     Nenhum.
##
## Returns:
##     Mesh: Malha colunar de conteiner com acabamento industrial.
##
## Raises:
##     Nenhuma excecao levantada.
func _build_container_mesh() -> Mesh:
	var scene: PackedScene = load("res://assets/models/boss/cargo-container-a.glb") as PackedScene
	if scene != null:
		var inst: Node = scene.instantiate()
		var mi: MeshInstance3D = inst.find_child("cargo-container-a", true, false) as MeshInstance3D
		if mi != null and mi.mesh != null:
			var m: Mesh = mi.mesh
			inst.free()
			return m
		inst.free()
	
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(3.2, 1.4, 1.4)
	return box


## Constrói a malha de torre industrial/guindaste portuario com plataforma metalica PBR.
##
## Args:
##     Nenhum.
##
## Returns:
##     Mesh: Malha detalhada de torre e gantry portuario.
##
## Raises:
##     Nenhuma excecao levantada.
func _build_crane_mesh() -> Mesh:
	var scene: PackedScene = load("res://assets/models/military/platform_high.glb") as PackedScene
	if scene != null:
		var inst: Node = scene.instantiate()
		var mi: MeshInstance3D = inst.find_child("platform_high", true, false) as MeshInstance3D
		if mi != null and mi.mesh != null:
			var m: Mesh = mi.mesh
			inst.free()
			return m
		inst.free()
	
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2.5, 6.0, 2.5)
	return box


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
		Vector3(100.0, 0.4, -5.0),
		# Bosques tropicais nos ilheus de aproximacao do Sudeste (rota do USS Vanguard)
		Vector3(660.0, 0.3, 660.0),
		Vector3(695.0, 0.3, 670.0),
		Vector3(675.0, 0.3, 705.0),
		Vector3(665.0, 0.3, 690.0),
		Vector3(540.0, 0.3, 510.0),
		Vector3(575.0, 0.3, 535.0),
		Vector3(555.0, 0.3, 550.0),
		Vector3(580.0, 0.3, 505.0),
		# Costa Sudeste de desembarque (choke points e estuario)
		Vector3(480.0, 0.3, 420.0),
		Vector3(505.0, 0.3, 410.0),
		Vector3(460.0, 0.3, 445.0),
		Vector3(520.0, 0.3, 450.0),
		Vector3(430.0, 0.3, 390.0),
		Vector3(410.0, 0.3, 420.0),
		Vector3(380.0, 0.3, 430.0),
		# Ilheu Leste
		Vector3(830.0, 0.3, 165.0),
		Vector3(865.0, 0.3, 195.0),
		Vector3(845.0, 0.3, 175.0),
		Vector3(870.0, 0.3, 160.0),
		# Faixa litoranea Sul e Leste
		Vector3(300.0, 0.3, 310.0),
		Vector3(260.0, 0.3, 315.0),
		Vector3(220.0, 0.3, 305.0),
		Vector3(160.0, 0.3, 310.0),
		Vector3(-140.0, 0.3, 310.0),
		Vector3(-280.0, 0.3, 290.0),
		Vector3(-340.0, 0.3, 280.0),
		Vector3(510.0, 0.3, 220.0),
		Vector3(515.0, 0.3, 140.0),
		Vector3(505.0, 0.3, 30.0),
		Vector3(520.0, 0.3, -80.0),
		Vector3(510.0, 0.3, -190.0),
		Vector3(500.0, 0.3, -280.0)
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
		var basis: Basis = Basis.IDENTITY.scaled(Vector3(1.6, 1.6, 1.6))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	
	containers_instance.multimesh = mm
	
	var container_mat: StandardMaterial3D = StandardMaterial3D.new()
	container_mat.albedo_color = Color(0.18, 0.32, 0.42, 1.0)
	container_mat.metallic = 0.5
	container_mat.roughness = 0.6
	containers_instance.material_override = container_mat


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
		var basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3(4.0, 4.0, 4.0))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	
	cranes_instance.multimesh = mm
	
	var steel_mat: StandardMaterial3D = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.22, 0.25, 0.28, 1.0)
	steel_mat.metallic = 0.75
	steel_mat.roughness = 0.45
	cranes_instance.material_override = steel_mat
