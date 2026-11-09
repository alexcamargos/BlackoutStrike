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
