# gdlint: disable=max-line-length
class_name TestPBRSurfaces
extends GutTest

## Testes unitarios para superficies PBR e shaders costeiros (Sprint 6).

const IslandTerrainMidwayScript = preload("res://scenes/environment/island_terrain_midway.gd")
const IslandPropsScript = preload("res://scenes/environment/island_props.gd")


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
	assert_eq(norm1.width, 1024, "ocean_wave_normal_1 deve ter resolucao horizontal de 1024.")
	assert_eq(norm1.height, 1024, "ocean_wave_normal_1 deve ter resolucao vertical de 1024.")
	
	assert_true(norm2.seamless, "ocean_wave_normal_2 deve possuir seamless ativado.")
	assert_true(norm2.as_normal_map, "ocean_wave_normal_2 deve estar configurado como mapa de normais.")
	assert_gt(norm2.bump_strength, 0.0, "ocean_wave_normal_2 deve ter bump_strength calibrado positivo.")
	assert_eq(norm2.width, 1024, "ocean_wave_normal_2 deve ter resolucao horizontal de 1024.")
	assert_eq(norm2.height, 1024, "ocean_wave_normal_2 deve ter resolucao vertical de 1024.")


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
	
	# Verificacao do metodo get_surface_altitude em todas as falesias e cotas
	assert_almost_eq(terrain.call("get_surface_altitude", 10.0, 10.0), 5.0, 0.1, "Altitude em (10, 10) deve refletir a falesia nordeste.")
	assert_almost_eq(terrain.call("get_surface_altitude", -112.0, -10.0), 5.5, 0.1, "Altitude em (-112, -10) deve refletir a falesia oeste.")
	assert_almost_eq(terrain.call("get_surface_altitude", 105.0, -55.0), 5.7, 0.1, "Altitude em (105, -55) deve refletir a falesia leste.")
	assert_almost_eq(terrain.call("get_surface_altitude", -45.0, 80.0), 4.5, 0.1, "Altitude em (-45, 80) deve refletir a falesia sul.")
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


func test_island_props_multimesh_instancing() -> void:
	var path_props: String = "res://scenes/environment/island_props.tscn"
	assert_true(ResourceLoader.exists(path_props), "A cena island_props.tscn deve existir.")
	
	var scene: PackedScene = load(path_props) as PackedScene
	var props_node: Node3D = scene.instantiate() as Node3D
	add_child_autofree(props_node)
	
	assert_not_null(props_node, "IslandProps deve ser instanciado sem erros.")
	assert_true(props_node.get_script() == IslandPropsScript, "IslandProps deve usar o script island_props.gd.")
	
	var palms: MultiMeshInstance3D = props_node.get("palms_instance") as MultiMeshInstance3D
	var containers: MultiMeshInstance3D = props_node.get("containers_instance") as MultiMeshInstance3D
	var cranes: MultiMeshInstance3D = props_node.get("cranes_instance") as MultiMeshInstance3D
	
	assert_not_null(palms, "palms_instance deve estar referenciado.")
	assert_not_null(containers, "containers_instance deve estar referenciado.")
	assert_not_null(cranes, "cranes_instance deve estar referenciado.")
	
	assert_not_null(palms.multimesh, "Palms deve possuir um MultiMesh atribuido.")
	assert_gt(palms.multimesh.instance_count, 0, "Deve haver palmeiras instanciadas no MultiMesh.")
	assert_eq(palms.multimesh.transform_format, MultiMesh.TRANSFORM_3D, "Formato de transform do MultiMesh deve ser TRANSFORM_3D.")
	for palm_pos: Vector3 in props_node.get("_palm_positions"):
		assert_gt(palm_pos.y, 0.15, "Nenhuma palmeira pode ser posicionada sobre o mar (y <= 0.15).")
	
	assert_not_null(containers.multimesh, "Containers deve possuir um MultiMesh atribuido.")
	assert_gt(containers.multimesh.instance_count, 0, "Deve haver conteineres instanciados no MultiMesh.")
	assert_eq(containers.multimesh.transform_format, MultiMesh.TRANSFORM_3D, "Formato de transform de conteineres deve ser TRANSFORM_3D.")
	
	assert_not_null(cranes.multimesh, "Cranes deve possuir um MultiMesh atribuido.")
	assert_gt(cranes.multimesh.instance_count, 0, "Deve haver guindastes instanciados no MultiMesh.")
	assert_eq(cranes.multimesh.transform_format, MultiMesh.TRANSFORM_3D, "Formato de transform de guindastes deve ser TRANSFORM_3D.")


func test_island_props_does_not_interfere_with_rescue_zones_or_helipad() -> void:
	var path_props: String = "res://scenes/environment/island_props.tscn"
	var scene: PackedScene = load(path_props) as PackedScene
	var props_node: Node3D = scene.instantiate() as Node3D
	add_child_autofree(props_node)
	
	# Pontos de abrigo conhecidos na missao 1
	var shelter_points: Array[Vector3] = [
		Vector3(-70, 0.5, -50),
		Vector3(-40, 0.5, 45),
		Vector3(50, 0.5, -60),
		Vector3(65, 0.5, 30),
		Vector3(-15, 0.5, -85),
		Vector3(20, 0.5, 75)
	]
	
	# Heliponto da base aliada
	var helipad_pos: Vector3 = Vector3(0, 0.5, -115)
	
	# Verifica que nenhum prop fica a menos de 10.0m de qualquer abrigo (evitando supressao indevida)
	for s_pos in shelter_points:
		var is_near: bool = props_node.call("is_point_near_prop", s_pos, 10.0)
		assert_false(is_near, "Nenhum prop pode estar a <= 10m do abrigo em %s." % str(s_pos))
	
	# Verifica que nenhum prop obstrui a zona de pouso do heliponto (raio de 8m)
	assert_false(props_node.call("is_point_near_prop", helipad_pos, 8.0), "Nenhum prop deve obstruir o heliponto.")


func test_mission_midway_contains_island_props() -> void:
	var scene: PackedScene = load("res://scenes/core/mission_01_midway.tscn") as PackedScene
	var mission_node: Node3D = scene.instantiate() as Node3D
	add_child_autofree(mission_node)
	
	var props_node: Node3D = mission_node.get_node_or_null("IslandProps") as Node3D
	assert_not_null(props_node, "O no IslandProps deve existir na arvore da Missao 1.")
	assert_true(props_node.get_script() == IslandPropsScript, "IslandProps na missao deve usar o script island_props.gd.")


func test_mission_midway_lighting_and_atmosphere_calibration() -> void:
	var env_res: Environment = load("res://scenes/core/world_environment.tres") as Environment
	assert_not_null(env_res, "O recurso world_environment.tres deve existir e ser valido.")
	
	# Validacao de nevoa atmosferica oceanica (TASK-090)
	assert_true(env_res.fog_enabled, "fog_enabled deve estar ativado no WorldEnvironment.")
	assert_almost_eq(env_res.fog_depth_begin, 120.0, 0.01, "fog_depth_begin deve iniciar a 120m.")
	assert_almost_eq(env_res.fog_light_color.r, 0.070588, 0.02, "fog_light_color R deve corresponder ao azul-profundo #122233.")
	assert_almost_eq(env_res.fog_light_color.g, 0.133333, 0.02, "fog_light_color G deve corresponder ao azul-profundo #122233.")
	assert_almost_eq(env_res.fog_light_color.b, 0.200000, 0.02, "fog_light_color B deve corresponder ao azul-profundo #122233.")
	assert_true(env_res.volumetric_fog_enabled, "volumetric_fog_enabled deve estar ativado.")
	assert_almost_eq(env_res.volumetric_fog_albedo.r, 0.070588, 0.02, "volumetric_fog_albedo R deve ser #122233.")
	assert_almost_eq(env_res.volumetric_fog_albedo.g, 0.133333, 0.02, "volumetric_fog_albedo G deve ser #122233.")
	assert_almost_eq(env_res.volumetric_fog_albedo.b, 0.200000, 0.02, "volumetric_fog_albedo B deve ser #122233.")
	
	# Validacao da luz solar direcional e sombras em cascata (TASK-090)
	var scene: PackedScene = load("res://scenes/core/mission_01_midway.tscn") as PackedScene
	var mission_node: Node3D = scene.instantiate() as Node3D
	add_child_autofree(mission_node)
	
	var sun: DirectionalLight3D = mission_node.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	assert_not_null(sun, "DirectionalLight3D deve existir na cena.")
	assert_true(sun.shadow_enabled, "Sombras devem estar ativadas na DirectionalLight3D.")
	assert_eq(sun.directional_shadow_mode, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "Modo de sombras deve ser PSSM 4 Splits (modo 2).")
	assert_almost_eq(sun.directional_shadow_max_distance, 180.0, 0.1, "directional_shadow_max_distance deve ser calibrada para 180.0m.")
	
	# Cor solar quente #FFF0D9
	assert_almost_eq(sun.light_color.r, 1.0, 0.02, "light_color R deve ser 1.0.")
	assert_almost_eq(sun.light_color.g, 0.941176, 0.02, "light_color G deve ser ~0.941 (#FFF0D9).")
	assert_almost_eq(sun.light_color.b, 0.850980, 0.02, "light_color B deve ser ~0.851 (#FFF0D9).")
	
	# Angulo rasante: ~55 graus elevacao (pitch -55 deg), ~-40 graus azimute
	var rot_deg: Vector3 = sun.rotation_degrees
	assert_almost_eq(rot_deg.x, -55.0, 1.0, "Elevacao do sol deve ser calibrada a 55 graus (pitch -55 deg).")
	assert_almost_eq(rot_deg.y, -40.0, 1.0, "Azimute do sol deve ser calibrado a -40 graus.")


func test_sunset_preset_pbr_materials_and_terrain3d_ready() -> void:
	assert_true(ClassDB.class_exists(&"Terrain3D"), "Plugin Terrain3D deve estar carregado e registrado no ClassDB.")

	var terrain_mat: ShaderMaterial = load("res://assets/shaders/terrain_slope_material.tres") as ShaderMaterial
	assert_not_null(terrain_mat, "terrain_slope_material.tres deve carregar.")
	assert_not_null(terrain_mat.get_shader_parameter("sand_arm"), "sand_arm PBR deve estar atribuido.")
	assert_not_null(terrain_mat.get_shader_parameter("grass_arm"), "grass_arm PBR deve estar atribuido.")
	assert_not_null(terrain_mat.get_shader_parameter("rock_arm"), "rock_arm PBR deve estar atribuido.")

	var sunset_env: Environment = load("res://scenes/core/world_environment_sunset.tres") as Environment
	assert_not_null(sunset_env, "world_environment_sunset.tres deve existir e ser valido.")
	assert_eq(sunset_env.background_mode, Environment.BG_SKY, "Preset sunset deve usar PanoramaSky.")

	var scene: PackedScene = load("res://scenes/core/mission_01_midway.tscn") as PackedScene
	var mission_node: Node3D = scene.instantiate() as Node3D
	add_child_autofree(mission_node)

	assert_not_null(mission_node.get_node_or_null("PortComplexA"), "PortComplexA deve estar instanciado na Missao 1.")
	assert_not_null(mission_node.get_node_or_null("CoastalNatureProps"), "CoastalNatureProps deve estar instanciado na Missao 1.")

	mission_node.call("apply_sunset_preset")
	var we: WorldEnvironment = mission_node.get_node("WorldEnvironment") as WorldEnvironment
	assert_eq(we.environment, sunset_env, "apply_sunset_preset deve alternar para world_environment_sunset.tres.")




