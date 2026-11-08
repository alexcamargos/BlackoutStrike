# gdlint: disable=max-line-length
class_name TestPBRSurfaces
extends GutTest

## Testes unitarios para superficies PBR e shaders costeiros (Sprint 6).

const IslandTerrainMidwayScript = preload("res://scenes/environment/island_terrain_midway.gd")


func test_ocean_wave_normal_textures_exist_and_configured() -> void:
	var path_norm1: String = "res://assets/textures/water/ocean_wave_normal_1.tres"
	var path_norm2: String = "res://assets/textures/water/ocean_wave_normal_2.tres"
	
	assert_true(ResourceLoader.exists(path_norm1), "Textura ocean_wave_normal_1.tres deve existir no projeto.")
	assert_true(ResourceLoader.exists(path_norm2), "Textura ocean_wave_normal_2.tres deve existir no projeto.")
	
	var norm1: NoiseTexture2D = load(path_norm1) as NoiseTexture2D
	var norm2: NoiseTexture2D = load(path_norm2) as NoiseTexture2D
	
	assert_not_null(norm1, "ocean_wave_normal_1.tres deve ser uma instancia valida de NoiseTexture2D.")
	assert_not_null(norm2, "ocean_wave_normal_2.tres deve ser uma instancia valida de NoiseTexture2D.")
	
	assert_true(norm1.seamless, "ocean_wave_normal_1 deve possuir seamless ativado.")
	assert_true(norm1.as_normal_map, "ocean_wave_normal_1 deve estar configurado como mapa de normais.")
	assert_gt(norm1.bump_strength, 0.0, "ocean_wave_normal_1 deve ter bump_strength calibrado positivo.")
	
	assert_true(norm2.seamless, "ocean_wave_normal_2 deve possuir seamless ativado.")
	assert_true(norm2.as_normal_map, "ocean_wave_normal_2 deve estar configurado como mapa de normais.")
	assert_gt(norm2.bump_strength, 0.0, "ocean_wave_normal_2 deve ter bump_strength calibrado positivo.")


func test_mission_midway_ocean_material_and_uniforms() -> void:
	var scene: PackedScene = load("res://scenes/core/mission_01_midway.tscn") as PackedScene
	assert_not_null(scene, "A cena mission_01_midway.tscn deve carregar sem erros.")
	
	var instance: Node3D = scene.instantiate() as Node3D
	add_child_autofree(instance)
	
	var ocean_mesh: MeshInstance3D = instance.get_node_or_null("OceanWaterMesh") as MeshInstance3D
	assert_not_null(ocean_mesh, "No OceanWaterMesh deve existir na cena.")
	
	var mat: ShaderMaterial = ocean_mesh.mesh.material as ShaderMaterial
	assert_not_null(mat, "OceanWaterMesh deve possuir um ShaderMaterial atribuido ao mesh.")
	
	var norm1: Texture2D = mat.get_shader_parameter("wave_normal_1") as Texture2D
	var norm2: Texture2D = mat.get_shader_parameter("wave_normal_2") as Texture2D
	assert_not_null(norm1, "wave_normal_1 deve estar atribuido no material do oceano.")
	assert_not_null(norm2, "wave_normal_2 deve estar atribuido no material do oceano.")
	
	var shallow: Color = mat.get_shader_parameter("shallow_color")
	var deep: Color = mat.get_shader_parameter("deep_color")
	var foam_depth: float = mat.get_shader_parameter("foam_intersection_depth")
	
	assert_almost_eq(shallow.r, 0.07843, 0.01, "shallow_color R deve corresponder ao turquesa litoraneo #14A6B8.")
	assert_almost_eq(shallow.g, 0.65098, 0.01, "shallow_color G deve corresponder ao turquesa litoraneo #14A6B8.")
	assert_almost_eq(shallow.b, 0.72156, 0.01, "shallow_color B deve corresponder ao turquesa litoraneo #14A6B8.")
	
	assert_almost_eq(deep.r, 0.01176, 0.01, "deep_color R deve corresponder ao azul-marinho abissal #031438.")
	assert_almost_eq(deep.g, 0.07843, 0.01, "deep_color G deve corresponder ao azul-marinho abissal #031438.")
	assert_almost_eq(deep.b, 0.21960, 0.01, "deep_color B deve corresponder ao azul-marinho abissal #031438.")
	
	assert_eq(foam_depth, 0.45, "foam_intersection_depth deve ser calibrado em 0.45.")


func test_island_terrain_midway_three_elevation_zones() -> void:
	var path_terrain: String = "res://scenes/environment/island_terrain_midway.tscn"
	assert_true(ResourceLoader.exists(path_terrain), "A cena island_terrain_midway.tscn deve existir.")
	
	var scene: PackedScene = load(path_terrain) as PackedScene
	var terrain: Node3D = scene.instantiate() as Node3D
	add_child_autofree(terrain)
	
	assert_not_null(terrain, "O terreno instanciado deve ser valido.")
	assert_true(terrain.get_script() == IslandTerrainMidwayScript, "O terreno deve utilizar island_terrain_midway.gd.")
	assert_eq(terrain.get("collision_layer"), 1, "Terreno deve colidir na camada 1 (world_static).")
	assert_true(terrain.is_in_group("world_static"), "Terreno deve pertencer ao grupo world_static.")
	
	# Validacao das 3 cotas topograficas
	var beach_mesh: MeshInstance3D = terrain.get("beach_mesh") as MeshInstance3D
	var plateau_mesh: MeshInstance3D = terrain.get("plateau_mesh") as MeshInstance3D
	var cliffs_container: Node3D = terrain.get("cliffs_container") as Node3D
	assert_not_null(beach_mesh, "BeachMesh deve estar configurado.")
	assert_not_null(plateau_mesh, "PlateauMesh deve estar configurado.")
	assert_not_null(cliffs_container, "Cliffs container deve estar configurado.")
	
	# Faixa de praia rasa (-0.2 a 0.3m)
	var beach_box: BoxMesh = beach_mesh.mesh as BoxMesh
	assert_not_null(beach_box, "BeachMesh deve utilizar malha BoxMesh.")
	var beach_top_y: float = beach_mesh.transform.origin.y + (beach_box.size.y * 0.5)
	var beach_bottom_y: float = beach_mesh.transform.origin.y - (beach_box.size.y * 0.5)
	assert_almost_eq(beach_top_y, 0.3, 0.01, "Cota maxima da praia deve ser 0.3m.")
	assert_almost_eq(beach_bottom_y, -0.2, 0.01, "Cota minima da praia deve ser -0.2m.")
	
	# Plato industrial (0.5m)
	var plateau_box: BoxMesh = plateau_mesh.mesh as BoxMesh
	assert_not_null(plateau_box, "PlateauMesh deve utilizar malha BoxMesh.")
	var plateau_top_y: float = plateau_mesh.transform.origin.y + (plateau_box.size.y * 0.5)
	assert_almost_eq(plateau_top_y, 0.5, 0.01, "Cota do plato industrial deve ser exatamente 0.5m.")
	
	# Falesias rochosas (0.5m a 6.0m)
	var cliff_children: Array[Node] = cliffs_container.get_children()
	assert_gt(cliff_children.size(), 0, "Deve haver falesias instanciadas no container.")
	for cliff in cliff_children:
		if cliff is MeshInstance3D and cliff.mesh is BoxMesh:
			var c_box: BoxMesh = cliff.mesh as BoxMesh
			var cliff_top_y: float = cliff.transform.origin.y + (c_box.size.y * 0.5)
			assert_gte(cliff_top_y, 0.5, "Topo da falesia deve ser maior ou igual a 0.5m.")
			assert_lte(cliff_top_y, 6.0, "Topo da falesia deve ser menor ou igual a 6.0m.")
	
	# Verificacao do metodo get_surface_altitude
	assert_almost_eq(terrain.call("get_surface_altitude", 10.0, 10.0), 5.0, 0.1, "Altitude em (10, 10) deve refletir a falesia nordeste.")
	assert_almost_eq(terrain.call("get_surface_altitude", 0.0, 0.0), 0.5, 0.1, "Altitude no centro deve refletir o plato a 0.5m.")
	assert_almost_eq(terrain.call("get_surface_altitude", 130.0, 0.0), 0.1, 0.1, "Altitude nos extremos deve refletir a praia rasa.")


func test_mission_midway_uses_modular_island_terrain() -> void:
	var scene: PackedScene = load("res://scenes/core/mission_01_midway.tscn") as PackedScene
	var mission_node: Node3D = scene.instantiate() as Node3D
	add_child_autofree(mission_node)
	
	var terrain_node: Node3D = mission_node.get_node_or_null("IslandTerrain") as Node3D
	assert_not_null(terrain_node, "O no IslandTerrain deve existir na missao.")
	assert_true(terrain_node.get_script() == IslandTerrainMidwayScript, "IslandTerrain deve usar o script island_terrain_midway.gd.")
	assert_eq(terrain_node.get("collision_layer"), 1, "IslandTerrain na missao deve ter collision_layer = 1.")

