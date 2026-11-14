extends GutTest

const VANGUARD_SCENE: PackedScene = preload("res://scenes/environment/uss_vanguard.tscn")


func test_hull_and_deck_use_custom_meshes_at_the_contract_scale() -> void:
	var vanguard: USSVanguard = VANGUARD_SCENE.instantiate() as USSVanguard
	add_child_autofree(vanguard)
	var hull: MeshInstance3D = vanguard.get_node("Meshes/Hull") as MeshInstance3D
	var deck: MeshInstance3D = vanguard.get_node("Meshes/FlightDeck") as MeshInstance3D
	assert_true(hull.mesh is ArrayMesh, "O casco deve usar uma malha própria.")
	assert_true(deck.mesh is ArrayMesh, "O convés deve usar uma malha própria.")
	var deck_bounds: AABB = deck.get_aabb()
	assert_almost_eq(deck_bounds.size.x, 36.0, 0.001, "Largura máxima do convés.")
	assert_almost_eq(deck_bounds.size.z, 150.0, 0.001, "Comprimento do convés.")
	assert_almost_eq(deck_bounds.end.y + deck.position.y, 0.5, 0.001, "Altura do convés.")
	var primitive_paths: Array[NodePath] = []
	for node: Node in vanguard.find_children("*", "MeshInstance3D", true, false):
		var visual: MeshInstance3D = node as MeshInstance3D
		if visual.mesh is PrimitiveMesh and visual.is_visible_in_tree():
			primitive_paths.append(vanguard.get_path_to(visual))
	assert_eq(primitive_paths, [], "Geometria visível não pode usar primitivas do Godot.")


func test_deck_collider_supports_spawn_and_respects_the_bow_outline() -> void:
	var vanguard: USSVanguard = VANGUARD_SCENE.instantiate() as USSVanguard
	add_child_autofree(vanguard)
	await get_tree().physics_frame
	var world: PhysicsDirectSpaceState3D = vanguard.get_world_3d().direct_space_state
	var center_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(0, 1, 0), Vector3(0, -1, 0), 1
	)
	var center_hit: Dictionary = world.intersect_ray(center_query)
	assert_eq(center_hit.get("collider"), vanguard.get_node("StaticBody3D"))
	var hit_position: Vector3 = center_hit.get("position", Vector3.ZERO)
	assert_almost_eq(hit_position.y, 0.5, 0.001, "Piso físico do heliponto.")
	var corner_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(-17, 1, -74), Vector3(-17, -1, -74), 1
	)
	assert_true(world.intersect_ray(corner_query).is_empty(), "O canto fora do convés precisa ficar livre.")
