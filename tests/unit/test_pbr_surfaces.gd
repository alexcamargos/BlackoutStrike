# gdlint: disable=max-line-length
class_name TestPBRSurfaces
extends GutTest

## Testes unitarios para superficies PBR e shaders costeiros (Sprint 6).


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
