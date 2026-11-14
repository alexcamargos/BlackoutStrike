@tool
extends Node3D

const Geometry = preload("res://scenes/environment/naval_mesh_geometry.gd")
const STEEL: Material = preload("res://assets/materials/mat_vanguard_steel.tres")
const DECK: Material = preload("res://assets/materials/mat_vanguard_deck.tres")
const CONCRETE: Material = preload("res://assets/materials/mat_concrete_pier.tres")
const SAND: Material = preload("res://assets/materials/mat_vanguard_sand.tres")
const ROCK: Material = preload("res://assets/materials/mat_vanguard_rock.tres")
const FOLIAGE: Material = preload("res://assets/materials/mat_vanguard_foliage.tres")
const YELLOW: Color = Color("#ffd35a")
const PLATFORM_Y: float = 2.4
const SUPPORT_COLLISION_LAYERS: int = 1 | FlightMovementController.CLEARANCE_LAYER
const TANK_CENTERS: Array[Vector2] = [Vector2(9, 11), Vector2(1, 14), Vector2(10, 20)]
const ISLAND_OUTLINE: PackedVector2Array = [
	Vector2(-36, -46), Vector2(-24, -67), Vector2(-3, -76), Vector2(20, -69),
	Vector2(34, -50), Vector2(39, -22), Vector2(37, 0), Vector2(43, 27),
	Vector2(34, 49), Vector2(15, 66), Vector2(-7, 69), Vector2(-29, 58),
	Vector2(-37, 38), Vector2(-34, 13), Vector2(-30, -8), Vector2(-40, -28),
]


func _ready() -> void:
	var island: Node3D = $SupportIsland
	var platform: StaticBody3D = $OffshoreLandingPlatform
	var docks: Node3D = $Docks
	_build_island(island)
	_build_platform(platform)
	_build_docks(docks, platform.position)
	var barge: MeshInstance3D = $ServiceBoats/LogisticsBarge/Hull
	barge.mesh = _build_barge()
	_build_collision(island, docks, platform)


func _build_island(island: Node3D) -> void:
	var seabed: PackedVector3Array = Geometry.ring(ISLAND_OUTLINE, -3.8, Vector2(1.14, 1.10))
	var shallows: PackedVector3Array = Geometry.ring(ISLAND_OUTLINE, -0.6, Vector2(1.06, 1.04))
	var shore: PackedVector3Array = Geometry.ring(ISLAND_OUTLINE, 0.24)
	var grassline: PackedVector3Array = Geometry.ring(ISLAND_OUTLINE, 0.85, Vector2(0.90, 0.94))
	var plateau: PackedVector3Array = Geometry.ring(ISLAND_OUTLINE, 3.0, Vector2(0.79, 0.88))
	var mesh: ArrayMesh = ArrayMesh.new()
	var sand: SurfaceTool = Geometry.surface(SAND)
	Geometry.add_band(sand, seabed, shallows)
	Geometry.add_band(sand, shallows, shore)
	Geometry.add_band(sand, shore, grassline)
	sand.commit(mesh)
	var rock: SurfaceTool = Geometry.surface(ROCK)
	Geometry.add_band(rock, grassline, plateau)
	rock.commit(mesh)
	var grass: SurfaceTool = Geometry.surface(FOLIAGE)
	Geometry.add_cap(grass, plateau, true)
	grass.commit(mesh)
	var terrain: MeshInstance3D = island.get_node("Terrain") as MeshInstance3D
	terrain.mesh = mesh

	var service_yard: SurfaceTool = Geometry.surface(CONCRETE)
	Geometry.add_panel(service_yard, Vector2(5, 0), Vector2(28, 93), 3.0, 3.13)
	var road: PackedVector3Array = Geometry.ring(Geometry.rectangle(Vector2(30, 0), Vector2(22, 7)), 3.02)
	road[1].y = 2.19
	road[2].y = 2.19
	Geometry.add_cap(service_yard, road, true)
	Geometry.add_panel(service_yard, Vector2(-17, -36), Vector2(12, 13), 3.0, 3.18)
	var pavement: MeshInstance3D = island.get_node("ServiceYard") as MeshInstance3D
	pavement.mesh = service_yard.commit()

	var palms: MultiMeshInstance3D = island.get_node("Palms") as MultiMeshInstance3D
	var locations: PackedVector2Array = [
		Vector2(-17, -49), Vector2(-6, -54), Vector2(9, -54), Vector2(18, -46),
		Vector2(-20, -25), Vector2(-14, -17), Vector2(-18, -5), Vector2(-13, 4),
		Vector2(-19, 14), Vector2(-21, 25), Vector2(-16, 35), Vector2(-12, 43),
		Vector2(-6, 53), Vector2(5, 53), Vector2(16, 50), Vector2(23, 41),
		Vector2(24, -19), Vector2(24, -30), Vector2(23, 18), Vector2(27, 27),
	]
	var trees: MultiMesh = MultiMesh.new()
	trees.transform_format = MultiMesh.TRANSFORM_3D
	trees.mesh = IslandProps.build_palm_mesh()
	trees.instance_count = locations.size()
	for index: int in range(locations.size()):
		var point: Vector2 = locations[index]
		var size: float = 0.86 + 0.12 * float(index % 4)
		var basis: Basis = Basis(Vector3.UP, 1.7 * float(index)).scaled(Vector3.ONE * size)
		trees.set_instance_transform(index, Transform3D(basis, Vector3(point.x, 3.0, point.y)))
	palms.multimesh = trees

	var equipment: MeshInstance3D = island.get_node("NavalEquipment") as MeshInstance3D
	equipment.mesh = _build_equipment()


func _build_equipment() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var tank: SurfaceTool = Geometry.surface(STEEL)
	for center: Vector2 in TANK_CENTERS:
		var shell: PackedVector2Array = _polygon(center, 3.15, 20)
		Geometry.add_prism(tank, shell, 3.13, 6.25)
		Geometry.add_band(tank, Geometry.ring(shell, 6.25),
			Geometry.ring(_polygon(center, 2.3, 20), 6.72))
		Geometry.add_cap(tank, Geometry.ring(_polygon(center, 2.3, 20), 6.72), true)
		Geometry.add_panel(tank, center, Vector2(1.1, 1.1), 6.72, 7.05)
	tank.commit(mesh)

	var paint: SurfaceTool = Geometry.surface(Geometry.paint(YELLOW, 0.66))
	_add_mast(paint, Vector2(-4, -30), 3.13, 14.1, 1.55)
	paint.commit(mesh)

	var radome: SurfaceTool = Geometry.surface(Geometry.paint(Color("#c2ccd0"), 0.7))
	var center: Vector2 = Vector2(-19, 26)
	var base: PackedVector2Array = _polygon(center, 1.65, 10)
	Geometry.add_prism(radome, base, 3.0, 4.8)
	var lower: PackedVector3Array = Geometry.ring(base, 4.8)
	for level: int in range(1, 7):
		var angle: float = PI * float(level) / 7.0
		var radius: float = 3.3 * sin(angle)
		var ring: PackedVector3Array = Geometry.ring(_polygon(center, radius, 10), 7.8 - 3.1 * cos(angle))
		Geometry.add_band(radome, lower, ring)
		lower = ring
	Geometry.add_cap(radome, lower, true)
	radome.commit(mesh)

	var beacon: SurfaceTool = Geometry.surface(Geometry.paint(Color("#fff0d9"), 0.4, 2.1))
	Geometry.add_prism(beacon, _polygon(Vector2(-4, -30), 0.25, 8), 14.1, 14.48)
	beacon.commit(mesh)
	return mesh


func _build_collision(island: Node3D, docks: Node3D, platform: StaticBody3D) -> void:
	var island_body: StaticBody3D = _add_static_body(island)
	for path: NodePath in [^"Terrain", ^"ServiceYard"]:
		var scenery: Node3D = island.get_node(path) as Node3D
		_add_scenery_surface(island_body, scenery)
	# O recife importado contém uma costa inteira e muitos triângulos. Só os
	# afloramentos acima do mar precisam participar da colisão de voo.
	for bounds: AABB in [
		AABB(Vector3(-40, -0.2, -63), Vector3(8, 1.1, 7)),
		AABB(Vector3(-29, -0.2, 63), Vector3(8, 1.1, 8)),
		AABB(Vector3(41, -0.2, -43), Vector3(5, 1.1, 7)),
	]:
		_add_box(island_body, bounds.get_center(), bounds.size)
	for path: NodePath in [^"MaintenanceHangar", ^"Workshop", ^"Warehouse", ^"CommunicationsDish", ^"Generator"]:
		_add_prop_box(island_body, island.get_node(path) as Node3D)
	for center: Vector2 in TANK_CENTERS:
		_add_box(island_body, Vector3(center.x, 5.09, center.y), Vector3(6.3, 3.92, 6.3))
	_add_box(island_body, Vector3(-4, 8.805, -30), Vector3(2.4, 11.35, 2.4))
	_add_box(island_body, Vector3(-19, 6.8, 26), Vector3(6.5, 7.6, 6.5))
	var palms: MultiMeshInstance3D = island.get_node("Palms") as MultiMeshInstance3D
	for index: int in range(palms.multimesh.instance_count):
		var tree: Transform3D = palms.multimesh.get_instance_transform(index)
		var size: float = tree.basis.get_scale().y
		_add_box(island_body, tree.origin + Vector3(0, 2.1 * size, 0), Vector3(0.75, 4.2, 0.75) * size)
		_add_box(island_body, tree.origin + Vector3(0, 3.85 * size, 0), Vector3(4.2, 1.3, 4.2) * size)

	var dock_body: StaticBody3D = _add_static_body(docks)
	_add_scenery_surface(dock_body, docks.get_node("Infrastructure") as MeshInstance3D)
	for path: NodePath in [^"CargoRed", ^"CargoBlue", ^"CargoReserve"]:
		_add_prop_box(dock_body, docks.get_node(path) as Node3D)
	_add_box(dock_body, Vector3(51, 9.17, 29), Vector3(8, 0.35, 7.2))
	for z: float in [25.6, 32.4]:
		_add_box(dock_body, Vector3(48.6, 5.67, z), Vector3(3.7, 7.0, 0.5))

	var platform_details: StaticBody3D = _add_static_body(platform)
	_add_box(platform_details, Vector3(-9.0, 5.425, 5.0), Vector3(1.1, 6.05, 1.1))

	var boats: Node3D = $ServiceBoats
	var boat_body: StaticBody3D = _add_static_body(boats)
	_add_prop_box(boat_body, boats.get_node("Tug") as Node3D)
	_add_prop_box(boat_body, boats.get_node("CrewLaunch") as Node3D)
	var barge: Node3D = boats.get_node("LogisticsBarge") as Node3D
	for part: Node in barge.get_children():
		_add_prop_box(boat_body, part as Node3D)


func _add_static_body(parent: Node3D) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "SceneryCollision"
	body.collision_layer = SUPPORT_COLLISION_LAYERS
	body.collision_mask = 0
	parent.add_child(body)
	return body


func _add_box(body: StaticBody3D, center: Vector3, size: Vector3) -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = box
	collider.position = center
	body.add_child(collider)


func _add_prop_box(body: StaticBody3D, prop: Node3D) -> void:
	var bounds: AABB = AABB()
	for visual: MeshInstance3D in _prop_meshes(prop):
		var local_transform: Transform3D = body.global_transform.affine_inverse() * visual.global_transform
		var part: AABB = local_transform * visual.get_aabb()
		bounds = part if bounds == AABB() else bounds.merge(part)
	if bounds.has_volume():
		_add_box(body, bounds.get_center(), bounds.size)


func _add_scenery_surface(body: StaticBody3D, prop: Node3D) -> void:
	var faces: PackedVector3Array = PackedVector3Array()
	for visual: MeshInstance3D in _prop_meshes(prop):
		var local_transform: Transform3D = body.global_transform.affine_inverse() * visual.global_transform
		faces.append_array(local_transform * visual.mesh.get_faces())
	if not faces.is_empty():
		var surface: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
		surface.set_faces(faces)
		surface.backface_collision = true
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = surface
		body.add_child(collider)


func _prop_meshes(prop: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if prop is MeshInstance3D:
		meshes.append(prop as MeshInstance3D)
	for node: Node in prop.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	return meshes


func _build_platform(platform: StaticBody3D) -> void:
	var outline: PackedVector2Array = _polygon(Vector2.ZERO, 14.0, 8, PI / 8.0)
	var surface: SurfaceTool = Geometry.surface(DECK)
	Geometry.add_prism(surface, outline, PLATFORM_Y - 0.62, PLATFORM_Y)
	var deck: MeshInstance3D = platform.get_node("Deck") as MeshInstance3D
	deck.mesh = surface.commit()
	var collision: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	var points: PackedVector3Array = Geometry.ring(outline, PLATFORM_Y)
	points.append_array(Geometry.ring(outline, PLATFORM_Y - 0.62))
	collision.points = points
	var collider: CollisionShape3D = platform.get_node("CollisionShape3D") as CollisionShape3D
	collider.shape = collision

	var mesh: ArrayMesh = ArrayMesh.new()
	var steel: SurfaceTool = Geometry.surface(STEEL)
	for point: Vector2 in outline:
		Geometry.add_prism(steel, _polygon(point * 0.83, 0.78, 10), -3.2, PLATFORM_Y - 0.36)
	_add_mast(steel, Vector2(-9.0, 5.0), PLATFORM_Y, 8.1, 0.64)
	steel.commit(mesh)

	var markings: SurfaceTool = Geometry.surface(Geometry.paint(YELLOW, 0.76))
	for index: int in range(outline.size()):
		var point: Vector2 = outline[index] * 0.94
		var end: Vector2 = outline[(index + 1) % outline.size()] * 0.94
		_mark(markings, point, end, 0.23, PLATFORM_Y)
		Geometry.add_prism(markings, _polygon(outline[index] * 0.83, 0.80, 10), 0.55, 0.91)
	var circle: PackedVector2Array = _polygon(Vector2.ZERO, 7.75, 48)
	for index: int in range(circle.size()):
		_mark(markings, circle[index], circle[(index + 1) % circle.size()], 0.32, PLATFORM_Y)
	markings.commit(mesh)

	var white: SurfaceTool = Geometry.surface(Geometry.paint(Color("#e8edf0"), 0.82))
	_mark(white, Vector2(-1.8, -2.3), Vector2(-1.8, 2.3), 0.48, PLATFORM_Y)
	_mark(white, Vector2(1.8, -2.3), Vector2(1.8, 2.3), 0.48, PLATFORM_Y)
	_mark(white, Vector2(-1.8, 0), Vector2(1.8, 0), 0.48, PLATFORM_Y)
	white.commit(mesh)
	var lamps: SurfaceTool = Geometry.surface(Geometry.paint(Color("#fff0d9"), 0.45, 2.0))
	for index: int in range(outline.size()):
		Geometry.add_prism(lamps, _polygon(outline[index] * 0.89, 0.28, 8), PLATFORM_Y, PLATFORM_Y + 0.19)
	Geometry.add_prism(lamps, _polygon(Vector2(-9.0, 5.0), 0.23, 8), 8.1, 8.45)
	lamps.commit(mesh)
	var details: MeshInstance3D = platform.get_node("Details") as MeshInstance3D
	details.mesh = mesh
	for point: Vector2 in outline:
		_add_box(platform, Vector3(point.x * 0.83, (PLATFORM_Y - 3.2 - 0.36) * 0.5, point.y * 0.83),
			Vector3(1.38, PLATFORM_Y + 3.2 - 0.36, 1.38))


func _build_docks(docks: Node3D, pad_position: Vector3) -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	var slabs: SurfaceTool = Geometry.surface(CONCRETE)
	var bridge_start: Vector2 = Vector2(pad_position.x, pad_position.z - 9.0)
	var bridge_end: Vector2 = Vector2(53, 31)
	Geometry.add_prism(slabs, Geometry.strip_outline(bridge_start, bridge_end, 5.0), 1.62, PLATFORM_Y)
	Geometry.add_panel(slabs, Vector2(48, 6), Vector2(12, 65), 1.1, 2.17)
	Geometry.add_panel(slabs, Vector2(42, 0), Vector2(17, 8), 1.1, 2.17)
	Geometry.add_panel(slabs, Vector2(-32, -31), Vector2(9, 42), 0.8, 1.75)
	slabs.commit(mesh)

	var steel: SurfaceTool = Geometry.surface(STEEL)
	var paint: SurfaceTool = Geometry.surface(Geometry.paint(YELLOW, 0.72))
	_add_gantry(paint, Vector2(47, 29), 2.17)
	_add_dock_edge(steel, paint, Vector2(53.6, -25), Vector2(53.6, 32), 2.17)
	_add_dock_edge(steel, paint, Vector2(-36.1, -49), Vector2(-36.1, -13), 1.75)
	var offset: Vector2 = (bridge_end - bridge_start).normalized().orthogonal() * 2.28
	for side: float in [-1.0, 1.0]:
		_add_dock_edge(steel, paint, bridge_start + offset * side, bridge_end + offset * side, PLATFORM_Y)
		_beam(steel, Vector3(bridge_start.x + offset.x * side, PLATFORM_Y + 0.29, bridge_start.y + offset.y * side),
			Vector3(bridge_end.x + offset.x * side, PLATFORM_Y + 0.29, bridge_end.y + offset.y * side), 0.12)
	steel.commit(mesh)
	paint.commit(mesh)
	var visual: MeshInstance3D = docks.get_node("Infrastructure") as MeshInstance3D
	visual.mesh = mesh


func _build_barge() -> ArrayMesh:
	var outline: PackedVector2Array = [
		Vector2(-2, -8), Vector2(1.9, -8), Vector2(2.7, -6), Vector2(2.7, 6),
		Vector2(1.8, 8), Vector2(-1.8, 8), Vector2(-2.7, 6), Vector2(-2.7, -6),
	]
	var hull: SurfaceTool = Geometry.surface(STEEL)
	Geometry.add_band(hull, Geometry.ring(outline, -0.90, Vector2(0.73, 0.89)), Geometry.ring(outline, 0.55))
	var mesh: ArrayMesh = hull.commit()
	var deck: SurfaceTool = Geometry.surface(DECK)
	Geometry.add_prism(deck, outline, 0.55, 0.88)
	deck.commit(mesh)
	var rails: SurfaceTool = Geometry.surface(Geometry.paint(YELLOW, 0.7))
	for side: float in [-1.0, 1.0]:
		Geometry.add_panel(rails, Vector2(side * 2.64, 0), Vector2(0.12, 12), 0.88, 1.10)
	rails.commit(mesh)
	return mesh


func _add_dock_edge(steel: SurfaceTool, paint: SurfaceTool, start: Vector2, end: Vector2, y: float) -> void:
	var count: int = ceili(start.distance_to(end) / 5.0)
	for index: int in range(count + 1):
		var point: Vector2 = start.lerp(end, float(index) / float(count))
		Geometry.add_prism(steel, _polygon(point, 0.47, 8), -2.0, y + 0.24)
		Geometry.add_prism(paint, _polygon(point, 0.49, 8), 0.58, 0.92)
	_mark(paint, start, end, 0.16, y)


func _add_mast(surface: SurfaceTool, center: Vector2, bottom: float, top: float, width: float) -> void:
	var base: PackedVector3Array = Geometry.ring(_polygon(center, width, 4, PI / 4.0), bottom)
	var cap: PackedVector3Array = Geometry.ring(_polygon(center, width * 0.25, 4, PI / 4.0), top)
	for index: int in range(base.size()):
		_beam(surface, base[index], cap[index], 0.20)
		var next: int = (index + 1) % base.size()
		for level: int in range(3):
			var start: float = float(level) / 3.0
			var finish: float = float(level + 1) / 3.0
			_beam(surface, base[index].lerp(cap[index], start), base[next].lerp(cap[next], finish), 0.12)


func _add_gantry(surface: SurfaceTool, center: Vector2, y: float) -> void:
	for side: float in [-1.0, 1.0]:
		var foot: Vector3 = Vector3(center.x, y, center.y + side * 3.4)
		var head: Vector3 = foot + Vector3(0, 7.0, 0)
		_beam(surface, foot, head, 0.44)
		_beam(surface, foot + Vector3(4.4, 0, 0), head, 0.27)
		_beam(surface, head, head + Vector3(8.0, 0, 0), 0.32)
		_beam(surface, head + Vector3(8.0, 0, 0), head + Vector3(0, 0, -side * 6.8), 0.24)


func _beam(surface: SurfaceTool, a: Vector3, b: Vector3, size: float) -> void:
	var axis: Vector3 = (b - a).normalized()
	var side: Vector3 = axis.cross(Vector3.FORWARD).normalized() * size * 0.5
	var up: Vector3 = side.cross(axis).normalized() * size * 0.5
	var lower: PackedVector3Array = [a - side - up, a + side - up, a + side + up, a - side + up]
	var upper: PackedVector3Array = [b - side - up, b + side - up, b + side + up, b - side + up]
	Geometry.add_band(surface, lower, upper)


func _mark(surface: SurfaceTool, start: Vector2, end: Vector2, width: float, y: float) -> void:
	Geometry.add_cap(surface, Geometry.ring(Geometry.strip_outline(start, end, width), y + 0.014), true)


func _polygon(center: Vector2, radius: float, sides: int, phase: float = 0.0) -> PackedVector2Array:
	var outline: PackedVector2Array = PackedVector2Array()
	for index: int in range(sides):
		outline.append(center + Vector2.from_angle(phase + TAU * float(index) / float(sides)) * radius)
	return outline
