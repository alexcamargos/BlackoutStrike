## Bateria de testes de integracao para o mapa expandido de 2.500 x 2.500m (Sprint 13).
class_name TestMapExpansionIntegration
extends GutTest

var mission_scene: PackedScene = preload("res://scenes/core/mission_01_midway.tscn")
var boundaries_scene: PackedScene = preload("res://scenes/environment/world_boundaries.tscn")


func test_world_boundaries_collision_shapes() -> void:
	var boundaries: StaticBody3D = boundaries_scene.instantiate() as StaticBody3D
	add_child_autofree(boundaries)
	
	assert_eq(boundaries.collision_layer, 1, "Limites mundiais devem estar na Camada 1 (World_Static).")
	assert_eq(boundaries.collision_mask, 0, "Limites mundiais nao precisam monitorar outros corpos.")
	
	var north_wall: CollisionShape3D = boundaries.get_node_or_null("NorthWall") as CollisionShape3D
	var south_wall: CollisionShape3D = boundaries.get_node_or_null("SouthWall") as CollisionShape3D
	var east_wall: CollisionShape3D = boundaries.get_node_or_null("EastWall") as CollisionShape3D
	var west_wall: CollisionShape3D = boundaries.get_node_or_null("WestWall") as CollisionShape3D
	
	assert_not_null(north_wall, "Parede norte deve existir.")
	assert_not_null(south_wall, "Parede sul deve existir.")
	assert_not_null(east_wall, "Parede leste deve existir.")
	assert_not_null(west_wall, "Parede oeste deve existir.")
	
	assert_almost_eq(north_wall.position.z, -1250.0, 0.1, "Parede norte deve estar em Z = -1250.")
	assert_almost_eq(south_wall.position.z, 1250.0, 0.1, "Parede sul deve estar em Z = +1250.")
	assert_almost_eq(east_wall.position.x, 1250.0, 0.1, "Parede leste deve estar em X = +1250.")
	assert_almost_eq(west_wall.position.x, -1250.0, 0.1, "Parede oeste deve estar em X = -1250.")


func test_mission_01_midway_macro_layout_integration() -> void:
	var mission_node: Node3D = mission_scene.instantiate() as Node3D
	add_child_autofree(mission_node)
	
	# 1. Verificacao dos limites do mundo
	var bounds: Node3D = mission_node.get_node_or_null("WorldBoundaries") as Node3D
	assert_not_null(bounds, "WorldBoundaries deve estar instanciado na Missao 1.")
	
	# 2. Porta-avioes USS Vanguard e Heliponto de apoio (Setor Sudeste)
	var vanguard_carrier: USSVanguard = mission_node.get_node_or_null("USS_Vanguard") as USSVanguard
	assert_not_null(vanguard_carrier, "USS_Vanguard deve estar instanciado na cena da Missao 1.")
	assert_eq(vanguard_carrier.position, Vector3(800.0, 0.0, 950.0), "USS Vanguard deve estar posicionado em (800, 0, 950).")
	
	var vanguard_helipad: AllyBaseHelipad = mission_node.get_node_or_null("Helipads/AllyBaseHelipad") as AllyBaseHelipad
	assert_not_null(vanguard_helipad, "AllyBaseHelipad do USS Vanguard deve existir.")
	assert_eq(vanguard_helipad.position, Vector3(800.0, 0.5, 950.0), "Heliponto Vanguard deve estar em (800, 0.5, 950).")
	
	# 3. Posto avancado de combustivel FOB no Atol Central
	var fob_depot: FuelDepot = mission_node.get_node_or_null("Helipads/FuelDepotFOB") as FuelDepot
	assert_not_null(fob_depot, "FuelDepotFOB deve existir na arvore de Helipads.")
	assert_eq(fob_depot.position, Vector3(-250.0, 0.5, 120.0), "FOB Depot deve estar em (-250, 0.5, 120).")
	
	# 4. Decolagem do helicóptero do jogador no USS Vanguard
	var player: PlayerHelicopter = mission_node.get_node_or_null("ActiveEntities/PlayerHelicopter") as PlayerHelicopter
	assert_not_null(player, "PlayerHelicopter deve existir na arvore.")
	assert_eq(player.position, Vector3(800.0, 1.0, 950.0), "Jogador deve iniciar na pista do USS Vanguard em (800, 1, 950).")
	
	# 5. Nau-capitania Apex Bastion em aguas profundas NW
	var boss: BossApexBastion = mission_node.get_node_or_null("ActiveEntities/Enemies/BossApexBastion") as BossApexBastion
	assert_not_null(boss, "BossApexBastion deve existir na arvore.")
	assert_eq(boss.position, Vector3(-900.0, 0.0, -900.0), "Boss deve estar ancorado em aguas profundas NW em (-900, 0, -900).")
	
	# 6. Oceano com seguidor de camera
	var ocean: FollowCameraOcean = mission_node.get_node_or_null("OceanWaterMesh") as FollowCameraOcean
	assert_not_null(ocean, "OceanWaterMesh deve utilizar o script FollowCameraOcean.")
	
	# Simula deslocamento do jogador para (-500, 4, -400)
	player.global_position = Vector3(-500.0, 4.0, -400.0)
	ocean.step()
	assert_almost_eq(ocean.global_position.x, -500.0, 0.1, "Oceano deve acompanhar a posicao X do jogador.")
	assert_almost_eq(ocean.global_position.y, 0.0, 0.001, "Oceano deve permanecer estritamente em Y = 0.0.")
	assert_almost_eq(ocean.global_position.z, -400.0, 0.1, "Oceano deve acompanhar a posicao Z do jogador.")
	
	# 7. Canal balizado de boias maritimas de aproximacao
	var channel_markers: Node3D = mission_node.get_node_or_null("SeaChannelMarkers") as Node3D
	assert_not_null(channel_markers, "SeaChannelMarkers deve existir para balizar a rota ate o Atol.")
	assert_gt(channel_markers.get_child_count(), 0, "Deve conter boias no canal maritimo de aproximacao.")


func test_vanguard_spawn_aligns_helicopter_with_deck_and_fills_vc01_frame() -> void:
	var mission: Node3D = mission_scene.instantiate() as Node3D
	add_child_autofree(mission)
	var player: PlayerHelicopter = mission.get_node("ActiveEntities/PlayerHelicopter") as PlayerHelicopter
	var deck: MeshInstance3D = mission.get_node("USS_Vanguard/Meshes/FlightDeck") as MeshInstance3D
	var deck_y: float = deck.to_global(deck.get_aabb().end).y
	var camera: TacticalCamera = mission.get_node("TacticalCamera") as TacticalCamera
	var expected_camera: Vector3 = player.global_position + Vector3(0, camera.camera_height, camera.camera_distance_z)
	assert_eq(camera.global_position, expected_camera, "A câmera deve enquadrar o spawn desde o primeiro quadro.")
	var model: Node3D = player.get_node("HelicopterMeshContainer/R9X_Mohawk_MilitaryModel") as Node3D
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var top_left: Vector2 = Vector2(INF, INF)
	var bottom_right: Vector2 = Vector2(-INF, -INF)
	var lowest_y: float = INF
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var visual: MeshInstance3D = node as MeshInstance3D
		if not visual.is_visible_in_tree():
			continue
		for surface: int in range(visual.mesh.get_surface_count()):
			var arrays: Array = visual.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				var world_vertex: Vector3 = visual.to_global(vertex)
				lowest_y = minf(lowest_y, world_vertex.y)
				var screen_point: Vector2 = camera.unproject_position(world_vertex)
				top_left = top_left.min(screen_point)
				bottom_right = bottom_right.max(screen_point)
	assert_almost_eq(lowest_y, deck_y, 0.02, "O trem de pouso deve tocar o convés no spawn.")
	var collision: CollisionShape3D = player.get_node("CollisionShape3D") as CollisionShape3D
	var hull_shape: BoxShape3D = collision.shape as BoxShape3D
	assert_almost_eq(collision.global_position.y - hull_shape.size.y * 0.5, deck_y, 0.02,
		"A base do colisor deve coincidir com o piso no spawn.")
	var size: Vector2 = bottom_right - top_left
	var screen_coverage: float = (size.x * size.y) / (viewport_size.x * viewport_size.y)
	assert_between(screen_coverage, 0.07, 0.13, "O retângulo projetado do R-9X deve ocupar 7% a 13% da tela.")


func test_vanguard_support_sector_has_offshore_landing_and_scenic_props() -> void:
	var mission: Node3D = mission_scene.instantiate() as Node3D
	add_child_autofree(mission)
	var sector: Node3D = mission.get_node_or_null("VanguardSupportSector") as Node3D
	assert_not_null(sector, "O setor de apoio deve aparecer na missão.")
	if sector == null:
		return
	var island: Node3D = sector.get_node("SupportIsland") as Node3D
	var boats: Node3D = sector.get_node("ServiceBoats") as Node3D
	var pad: StaticBody3D = sector.get_node("OffshoreLandingPlatform") as StaticBody3D
	var carrier: USSVanguard = mission.get_node("USS_Vanguard") as USSVanguard
	var carrier_deck: MeshInstance3D = carrier.get_node("Meshes/FlightDeck") as MeshInstance3D
	for node: Node in island.find_children("*", "MeshInstance3D", true, false):
		var visual: MeshInstance3D = node as MeshInstance3D
		var island_to_carrier: Transform3D = carrier.global_transform.affine_inverse() * visual.global_transform
		var island_bounds: AABB = island_to_carrier * visual.get_aabb()
		assert_lt(island_bounds.end.x, carrier_deck.get_aabb().position.x - 4.0,
			"A ilha precisa manter um canal livre junto ao navio: %s" % visual.name)
	assert_gte(boats.get_child_count(), 3, "Rebocador, lancha e barcaça devem compor o setor.")
	assert_eq(sector.find_children("*", "Area3D", true, false).size(), 0,
		"A configuração de resgate e abastecimento permanece no heliponto original.")
	for node: Node in sector.find_children("*", "MeshInstance3D", true, false):
		var visual: MeshInstance3D = node as MeshInstance3D
		assert_false(visual.mesh is PrimitiveMesh and visual.is_visible_in_tree(),
			"O cenário deve usar malhas próprias ou importadas: %s" % visual.name)
	await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = sector.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		pad.global_position + Vector3.UP * 4.0, pad.global_position + Vector3.DOWN * 2.0, 1
	)
	var hit: Dictionary = space.intersect_ray(query)
	assert_eq(hit.get("collider"), pad, "A plataforma deve sustentar o helicóptero.")
	var contact: Vector3 = hit.get("position", Vector3.ZERO)
	var deck: MeshInstance3D = pad.get_node("Deck") as MeshInstance3D
	assert_almost_eq(contact.y, deck.to_global(deck.get_aabb().end).y, 0.02,
		"A colisão deve coincidir com o piso da plataforma.")

	var hangar_roof: Vector3 = sector.to_global(Vector3(7, 9.63, -33))
	query.from = hangar_roof + Vector3.UP * 2.0
	query.to = hangar_roof - Vector3.UP * 2.0
	var roof_hit: Dictionary = space.intersect_ray(query)
	assert_false(roof_hit.is_empty(), "O teto do galpão deve ter colisão.")
	query.from = sector.to_global(Vector3(-6, 4.0, -33))
	query.to = sector.to_global(Vector3(7, 4.0, -33))
	assert_false(space.intersect_ray(query).is_empty(), "Um voo baixo deve encontrar a parede do galpão.")
	for point: Vector3 in [Vector3(-12, 3.0, -8), Vector3(46, 2.17, 10), Vector3(60.5, 0.88, 19)]:
		query.from = sector.to_global(point + Vector3.UP * 1.0)
		query.to = sector.to_global(point - Vector3.UP * 0.7)
		assert_false(space.intersect_ray(query).is_empty(), "Ilha, cais e barcaça devem ter superfície sólida: %s" % point)


func test_vanguard_cruise_clears_hangar_and_low_flight_stops_at_wall() -> void:
	var mission: Node3D = mission_scene.instantiate() as Node3D
	add_child_autofree(mission)
	var sector: Node3D = mission.get_node("VanguardSupportSector") as Node3D
	var player: PlayerHelicopter = mission.get_node("ActiveEntities/PlayerHelicopter") as PlayerHelicopter
	player.set_physics_process(false)
	player.clear_aim_target()
	player.rotation.y = -PI / 2.0
	var start: Vector3 = sector.to_global(Vector3(-30, 4.0, -33))
	player.global_position = start
	var direction: Vector3 = sector.global_transform.basis.x.normalized()
	Input.action_press("move_east", direction.x)
	Input.action_press("move_south", direction.z)
	for frame: int in range(185):
		await get_tree().physics_frame
		player._process_flight_controls(1.0 / 60.0)
	assert_gt(sector.to_local(player.global_position).x, 14.0,
		"O cruzeiro deve completar a passagem acima do galpão.")
	player.global_position = start
	player.velocity = Vector3.ZERO
	Input.action_press("altitude_descend")
	for frame: int in range(140):
		await get_tree().physics_frame
		player._process_flight_controls(1.0 / 60.0)
	Input.action_release("move_east")
	Input.action_release("move_south")
	Input.action_release("altitude_descend")
	assert_lt(sector.to_local(player.global_position).x, 0.5,
		"O voo baixo deve parar antes de atravessar a parede.")
	assert_lt(player.global_position.y, 5.0, "O comando de descida tem prioridade sobre a assistência.")


func test_vanguard_offshore_platform_allows_manual_landing() -> void:
	var mission: Node3D = mission_scene.instantiate() as Node3D
	add_child_autofree(mission)
	var player: PlayerHelicopter = mission.get_node("ActiveEntities/PlayerHelicopter") as PlayerHelicopter
	var path: NodePath = ^"VanguardSupportSector/OffshoreLandingPlatform/Deck"
	var deck: MeshInstance3D = mission.get_node(path) as MeshInstance3D
	var floor_y: float = deck.to_global(deck.get_aabb().end).y
	player.set_physics_process(false)
	player.global_position = deck.global_position + Vector3.UP * 5.0
	Input.action_press("altitude_descend")
	for frame: int in range(38):
		await get_tree().physics_frame
		player._process_flight_controls(1.0 / 60.0)
	Input.action_release("altitude_descend")
	assert_true(player.is_on_floor(), "O helicóptero deve pousar na plataforma elevada.")
	assert_almost_eq(player.global_position.y - 0.5, floor_y, 0.02, "O pouso deve manter o trem de pouso no piso.")
