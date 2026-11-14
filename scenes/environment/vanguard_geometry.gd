@tool
extends Node3D

## Malhas locais do navio. O eixo -Z aponta para a proa e a água fica em Y = 0.
const Geometry = preload("res://scenes/environment/naval_mesh_geometry.gd")
const DECK_Y: float = 0.5
const DECK_OUTLINE: PackedVector2Array = [
	Vector2(-8.5, -75.0), Vector2(8.5, -75.0),
	Vector2(14.0, -65.0), Vector2(17.5, -39.0),
	Vector2(17.5, 37.0), Vector2(16.0, 68.0), Vector2(12.5, 75.0),
	Vector2(-11.0, 75.0), Vector2(-15.5, 67.0), Vector2(-18.5, 31.0),
	Vector2(-18.5, -21.0), Vector2(-15.5, -46.0), Vector2(-12.5, -66.0),
]
const STEEL: Material = preload("res://assets/materials/mat_vanguard_steel.tres")
const DECK_SURFACE: Material = preload("res://assets/materials/mat_vanguard_deck.tres")
const SAFETY_YELLOW: Color = Color("#ffd35a")
const DECK_WHITE: Color = Color("#e4e9eb")


func _ready() -> void:
	var deck: MeshInstance3D = $FlightDeck
	var outline_bottom: PackedVector3Array = Geometry.ring(DECK_OUTLINE, -0.16)
	var outline_top: PackedVector3Array = Geometry.ring(DECK_OUTLINE, DECK_Y)
	var deck_surface: SurfaceTool = Geometry.surface(DECK_SURFACE)
	Geometry.add_band(deck_surface, outline_bottom, outline_top)
	Geometry.add_cap(deck_surface, outline_top, true)
	Geometry.add_cap(deck_surface, outline_bottom, false)
	deck.mesh = deck_surface.commit()

	var hull: MeshInstance3D = $Hull
	hull.mesh = _build_hull()
	var markings: MeshInstance3D = $Markings
	markings.mesh = _build_markings()
	var details: MeshInstance3D = $DeckDetails
	details.mesh = _build_deck_details()

	var tower: MeshInstance3D = $Superstructure/Island
	tower.mesh = _build_island()
	var radar: MeshInstance3D = $Superstructure/RadarMast/RadarDish/DishMesh
	radar.mesh = _build_radar()


func create_deck_collider() -> ConvexPolygonShape3D:
	var floor_shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	var floor_points: PackedVector3Array = Geometry.ring(DECK_OUTLINE, DECK_Y)
	floor_points.append_array(Geometry.ring(DECK_OUTLINE, -0.16))
	floor_shape.points = floor_points
	return floor_shape


func _build_hull() -> ArrayMesh:
	var keel: PackedVector3Array = Geometry.ring(DECK_OUTLINE, -5.2, Vector2(0.50, 0.86))
	var chine: PackedVector3Array = Geometry.ring(DECK_OUTLINE, -2.8, Vector2(0.79, 0.94))
	var waterline: PackedVector3Array = Geometry.ring(DECK_OUTLINE, -0.8, Vector2(0.84, 0.96))
	var shoulders: PackedVector3Array = Geometry.ring(DECK_OUTLINE, -0.16, Vector2(0.91, 0.99))
	# A proa sobe da quilha e abre em direção à borda do convés.
	for index: int in range(3):
		keel[index].y += 1.1
		keel[index].z += 3.5
	var surface: SurfaceTool = Geometry.surface(STEEL)
	Geometry.add_band(surface, keel, chine)
	Geometry.add_band(surface, chine, waterline)
	Geometry.add_band(surface, waterline, shoulders)
	Geometry.add_band(surface, shoulders, Geometry.ring(DECK_OUTLINE, -0.16))
	Geometry.add_cap(surface, keel, false)
	return surface.commit()


func _build_markings() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var white: SurfaceTool = Geometry.surface(Geometry.paint(DECK_WHITE, 0.77))
	for index: int in range(DECK_OUTLINE.size()):
		var start: Vector2 = DECK_OUTLINE[index] * Vector2(0.96, 0.985)
		var end: Vector2 = DECK_OUTLINE[(index + 1) % DECK_OUTLINE.size()] * Vector2(0.96, 0.985)
		_add_stripe(white, start, end, 0.16)
	# A marca de pouso substitui a plataforma alta; o volume de serviço continua na missão.
	for index: int in range(48):
		var start_angle: float = TAU * float(index) / 48.0
		var end_angle: float = TAU * float(index + 1) / 48.0
		_add_stripe(white, Vector2.from_angle(start_angle) * 6.7, Vector2.from_angle(end_angle) * 6.7, 0.26)
	_add_stripe(white, Vector2(-1.45, -2.15), Vector2(-1.45, 2.15), 0.42)
	_add_stripe(white, Vector2(1.45, -2.15), Vector2(1.45, 2.15), 0.42)
	_add_stripe(white, Vector2(-1.65, 0.0), Vector2(1.65, 0.0), 0.42)
	white.commit(mesh)

	var yellow: SurfaceTool = Geometry.surface(Geometry.paint(SAFETY_YELLOW, 0.72))
	for z: int in range(-65, 65, 8):
		if absi(z) >= 12:
			_add_stripe(yellow, Vector2(-4.5, z), Vector2(-4.5, z + 4), 0.22)
	for x: float in [-7.0, 7.0]:
		_add_stripe(yellow, Vector2(x - 3.0, -56.0), Vector2(x + 3.0, -56.0), 0.34)
		_add_stripe(yellow, Vector2(x - 3.0, 59.0), Vector2(x + 3.0, 59.0), 0.34)
	for z: int in range(-22, 3, 2):
		_add_stripe(yellow, Vector2(9.2, z + 1), Vector2(10.4, z), 0.21)
	yellow.commit(mesh)

	var seams: SurfaceTool = Geometry.surface(Geometry.paint(Color("#333a42"), 0.92))
	for z: int in range(-60, 68, 8):
		_add_stripe(seams, Vector2(-10.2, z), Vector2(10.2, z), 0.035, 0.004)
	for x: float in [-10.2, 10.2]:
		_add_stripe(seams, Vector2(x, -62), Vector2(x, 68), 0.045, 0.004)
	seams.commit(mesh)
	return mesh


func _build_deck_details() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var steel: SurfaceTool = Geometry.surface(STEEL)
	for index: int in range(DECK_OUTLINE.size()):
		var start: Vector2 = DECK_OUTLINE[index] * Vector2(0.985, 0.992)
		var end: Vector2 = DECK_OUTLINE[(index + 1) % DECK_OUTLINE.size()] * Vector2(0.985, 0.992)
		Geometry.add_prism(steel, Geometry.strip_outline(start, end, 0.14), 1.27, 1.40)
		var segments: int = ceili(start.distance_to(end) / 3.4)
		for segment: int in range(segments):
			var post: Vector2 = start.lerp(end, float(segment) / float(segments))
			Geometry.add_panel(steel, post, Vector2(0.16, 0.16), DECK_Y, 1.40)
	for side: float in [-1.0, 1.0]:
		for z: float in [-47.0, -27.0, 23.0, 43.0]:
			Geometry.add_panel(steel, Vector2(side * 14.6, z), Vector2(1.25, 2.8), DECK_Y, 1.15)
		for z: int in range(-34, 38, 9):
			var edge: float = -18.5 if side < 0.0 else 17.5
			if side < 0.0 and (z < -21 or z > 31):
				continue
			Geometry.add_panel(steel, Vector2(edge - side * 0.18, z), Vector2(0.48, 2.7), -0.72, 0.34)
	steel.commit(mesh)

	var lamps: SurfaceTool = Geometry.surface(Geometry.paint(Color("#fff0d9"), 0.35, 2.0))
	for side: float in [-1.0, 1.0]:
		for z: int in range(-60, 65, 10):
			Geometry.add_panel(lamps, Vector2(side * 11.8, z), Vector2(0.22, 0.4), DECK_Y, 0.54)
	lamps.commit(mesh)
	for side: float in [-1.0, 1.0]:
		var color: Color = Color("#ef544b") if side < 0.0 else Color("#61e8a8")
		var nav: SurfaceTool = Geometry.surface(Geometry.paint(color, 0.3, 2.5))
		Geometry.add_panel(nav, Vector2(side * 12.4, -65.0), Vector2(0.30, 0.38), DECK_Y, 0.78)
		nav.commit(mesh)
	return mesh


func _build_island() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var footprint: PackedVector2Array = [
		Vector2(-2.2, -10), Vector2(2.1, -10), Vector2(3.4, -7), Vector2(3.4, 8),
		Vector2(2.2, 10), Vector2(-2.4, 10), Vector2(-3.4, 8), Vector2(-3.4, -7),
	]
	var steel: SurfaceTool = Geometry.surface(STEEL)
	var foot: PackedVector3Array = Geometry.ring(footprint, 0.0)
	var upper: PackedVector3Array = Geometry.ring(footprint, 5.3, Vector2(0.78, 0.86))
	Geometry.add_band(steel, foot, upper)
	Geometry.add_cap(steel, upper, true)
	var bridge: PackedVector2Array = Geometry.rectangle(Vector2(0, -2.2), Vector2(6.9, 10.4))
	Geometry.add_prism(steel, bridge, 5.0, 5.8)
	Geometry.add_prism(steel, bridge, 7.24, 7.63)
	Geometry.add_panel(steel, Vector2(0.4, 2.6), Vector2(2.2, 2.5), 5.3, 8.35)
	Geometry.add_panel(steel, Vector2(0, 2), Vector2(0.68, 0.74), 7.5, 13.7)
	for y: float in [9.35, 11.8]:
		Geometry.add_panel(steel, Vector2(0, 2), Vector2(5.9, 0.33), y, y + 0.23)
		Geometry.add_panel(steel, Vector2(0, 2), Vector2(0.33, 2.8), y, y + 0.23)
	for x: float in [-2.6, 2.6]:
		Geometry.add_panel(steel, Vector2(x, 2), Vector2(0.12, 0.12), 11.8, 14.8)
	steel.commit(mesh)

	var glass: SurfaceTool = Geometry.surface(Geometry.paint(Color("#152c3a"), 0.24, 0.14))
	Geometry.add_panel(glass, Vector2(0, -2.2), Vector2(6.55, 10.06), 5.8, 7.24)
	glass.commit(mesh)

	var mullions: SurfaceTool = Geometry.surface(STEEL)
	for x: int in range(-3, 4):
		Geometry.add_panel(mullions, Vector2(x, -7.24), Vector2(0.12, 0.16), 5.8, 7.24)
	for z: int in range(-6, 3):
		for x: float in [-3.29, 3.29]:
			Geometry.add_panel(mullions, Vector2(x, z), Vector2(0.14, 0.13), 5.8, 7.24)
	for z: float in [-5.3, 3.8]:
		Geometry.add_panel(mullions, Vector2(-3.06, z), Vector2(0.36, 1.4), 0.14, 2.2)
		for y: float in [0.45, 1.02, 1.59]:
			Geometry.add_panel(mullions, Vector2(-3.31, z), Vector2(0.17, 1.08), y, y + 0.12)
	mullions.commit(mesh)
	return mesh


func _build_radar() -> ArrayMesh:
	var surface: SurfaceTool = Geometry.surface(STEEL)
	for x: float in [-2.25, 2.25]:
		Geometry.add_panel(surface, Vector2(x, 0), Vector2(0.14, 0.36), -0.55, 0.55)
	for y: float in [-0.55, -0.19, 0.19, 0.55]:
		Geometry.add_panel(surface, Vector2.ZERO, Vector2(4.5, 0.19), y - 0.043, y + 0.043)
	Geometry.add_panel(surface, Vector2.ZERO, Vector2(0.36, 0.36), -0.72, 0.55)
	return surface.commit()


func _add_stripe(surface: SurfaceTool, start: Vector2, end: Vector2, width: float, elevation: float = 0.012) -> void:
	Geometry.add_cap(surface, Geometry.ring(Geometry.strip_outline(start, end, width), DECK_Y + elevation), true)
