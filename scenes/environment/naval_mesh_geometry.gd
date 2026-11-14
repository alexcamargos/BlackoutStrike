extends RefCounted

## Construção de malhas costeiras em espaço local com faces horárias.

static func surface(material: Material) -> SurfaceTool:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	return surface


static func paint(color: Color, roughness: float, emission: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.emission_enabled = emission > 0.0
	material.emission = color
	material.emission_energy_multiplier = emission
	return material


static func ring(outline: PackedVector2Array, y: float, scale_xz: Vector2 = Vector2.ONE) -> PackedVector3Array:
	var ring: PackedVector3Array = PackedVector3Array()
	for point: Vector2 in outline:
		ring.append(Vector3(point.x * scale_xz.x, y, point.y * scale_xz.y))
	return ring


static func rectangle(center: Vector2, size: Vector2) -> PackedVector2Array:
	var half: Vector2 = size * 0.5
	return [center - half, center + Vector2(half.x, -half.y), center + half, center + Vector2(-half.x, half.y)]


static func strip_outline(start: Vector2, end: Vector2, width: float) -> PackedVector2Array:
	var direction: Vector2 = (end - start).normalized()
	var offset: Vector2 = Vector2(-direction.y, direction.x) * (width * 0.5)
	return [start - offset, end - offset, end + offset, start + offset]


static func add_panel(surface: SurfaceTool, center: Vector2, size: Vector2, bottom: float, top: float) -> void:
	add_prism(surface, rectangle(center, size), bottom, top)


static func add_prism(surface: SurfaceTool, outline: PackedVector2Array, bottom: float, top: float) -> void:
	var lower: PackedVector3Array = ring(outline, bottom)
	var upper: PackedVector3Array = ring(outline, top)
	add_band(surface, lower, upper)
	add_cap(surface, upper, true)
	add_cap(surface, lower, false)


static func add_band(surface: SurfaceTool, lower: PackedVector3Array, upper: PackedVector3Array) -> void:
	for index: int in range(upper.size()):
		var next: int = (index + 1) % upper.size()
		add_triangle(surface, upper[index], lower[index], lower[next])
		add_triangle(surface, upper[index], lower[next], upper[next])


static func add_cap(surface: SurfaceTool, ring: PackedVector3Array, top: bool) -> void:
	var outline: PackedVector2Array = PackedVector2Array()
	for point: Vector3 in ring:
		outline.append(Vector2(point.x, point.z))
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(outline)
	for index: int in range(0, triangles.size(), 3):
		var a: Vector3 = ring[triangles[index]]
		var b: Vector3 = ring[triangles[index + 1]]
		var c: Vector3 = ring[triangles[index + 2]]
		var faces_up: bool = (b - a).cross(c - a).y < 0.0
		if faces_up == top:
			add_triangle(surface, a, b, c)
		else:
			add_triangle(surface, a, c, b)


static func add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# O Godot considera a face da frente em sentido horário.
	var normal: Vector3 = (c - a).cross(b - a).normalized()
	surface.set_normal(normal)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
