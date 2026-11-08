## Testes unitarios para efeitos visuais, balistica emissiva e feedback de combate (Sprint 8).
extends GutTest


func test_vulcan_tracer_ballistics_and_emission() -> void:
	var scene: PackedScene = load("res://scenes/weapons/projectile_vulcan.tscn")
	assert_not_null(scene, "Cena do Vulcan deve existir.")
	var inst: Projectile = scene.instantiate() as Projectile
	add_child_autofree(inst)
	
	var mesh_inst: MeshInstance3D = inst.get_node_or_null("MeshInstance3D") as MeshInstance3D
	assert_not_null(mesh_inst, "Vulcan deve possuir MeshInstance3D para o tracante.")
	assert_true(mesh_inst.mesh is CapsuleMesh, "Tracante do Vulcan deve ser uma capsula alongada.")
	
	var mat: StandardMaterial3D = mesh_inst.mesh.material as StandardMaterial3D
	if mat == null and mesh_inst.material_override is StandardMaterial3D:
		mat = mesh_inst.material_override as StandardMaterial3D
	assert_not_null(mat, "Tracante deve possuir StandardMaterial3D.")
	assert_true(mat.emission_enabled, "Emissao deve estar ativada.")
	assert_gte(mat.emission_energy_multiplier, 4.0, "Intensidade da emissao deve ser >= 4.0.")
	assert_gt(mat.emission.r, 0.7, "Cor de emissao deve ser amarela intensa (canal R alto).")
	assert_gt(mat.emission.g, 0.6, "Cor de emissao deve ser amarela intensa (canal G alto).")


func test_hydra_and_hellfire_gpu_particles_trails() -> void:
	var hydra_scene: PackedScene = load("res://scenes/weapons/projectile_hydra.tscn")
	var hydra_inst: Projectile = hydra_scene.instantiate() as Projectile
	add_child_autofree(hydra_inst)
	
	var hydra_particles: GPUParticles3D = hydra_inst.get_node_or_null("TrailParticles") as GPUParticles3D
	if hydra_particles == null:
		hydra_particles = hydra_inst.get_node_or_null("SmokeTrailParticles") as GPUParticles3D
	assert_not_null(hydra_particles, "Foguete Hydra deve possuir no GPUParticles3D para esteira de fumaca e fagulhas.")
	assert_false(hydra_particles.local_coords, "Particulas de esteira devem operar em coordenadas globais (local_coords = false).")
	
	var hellfire_scene: PackedScene = load("res://scenes/weapons/projectile_hellfire.tscn")
	var hellfire_inst: Projectile = hellfire_scene.instantiate() as Projectile
	add_child_autofree(hellfire_inst)
	
	var hellfire_particles: GPUParticles3D = hellfire_inst.get_node_or_null("TrailParticles") as GPUParticles3D
	if hellfire_particles == null:
		hellfire_particles = hellfire_inst.get_node_or_null("SmokeTrailParticles") as GPUParticles3D
	assert_not_null(hellfire_particles, "Missil Hellfire deve possuir no GPUParticles3D para esteira de fumaca e fagulhas.")
	assert_false(hellfire_particles.local_coords, "Particulas do Hellfire devem operar em coordenadas globais.")


func test_enemy_projectiles_plasma_emissive_palette() -> void:
	var enemy_bullet_scene: PackedScene = load("res://scenes/weapons/projectile_enemy_bullet.tscn")
	var bullet_inst: Projectile = enemy_bullet_scene.instantiate() as Projectile
	add_child_autofree(bullet_inst)
	
	var bullet_mesh: MeshInstance3D = bullet_inst.get_node_or_null("MeshInstance3D") as MeshInstance3D
	assert_not_null(bullet_mesh, "Projetil inimigo deve possuir MeshInstance3D.")
	var bullet_mat: StandardMaterial3D = bullet_mesh.mesh.material as StandardMaterial3D
	if bullet_mat == null and bullet_mesh.material_override is StandardMaterial3D:
		bullet_mat = bullet_mesh.material_override as StandardMaterial3D
	assert_not_null(bullet_mat, "Projetil inimigo deve possuir material emissivo.")
	assert_true(bullet_mat.emission_enabled, "Emissao do projetil inimigo deve estar ativada.")
	assert_gte(bullet_mat.emission_energy_multiplier, 4.0, "Energia da emissao deve ser >= 4.0.")
	assert_gt(bullet_mat.emission.r, bullet_mat.emission.g, "Plasma inimigo deve tender a carmesim/laranja (R > G).")
	
	var sam_scene: PackedScene = load("res://scenes/weapons/projectile_enemy_sam_missile.tscn")
	var sam_inst: Projectile = sam_scene.instantiate() as Projectile
	add_child_autofree(sam_inst)
	
	var sam_particles: GPUParticles3D = sam_inst.get_node_or_null("TrailParticles") as GPUParticles3D
	if sam_particles == null:
		sam_particles = sam_inst.get_node_or_null("SmokeTrailParticles") as GPUParticles3D
	assert_not_null(sam_particles, "Missil SAM inimigo deve possuir GPUParticles3D de esteira.")


func test_impact_effect_surface_discrimination() -> void:
	var scene: PackedScene = load("res://scenes/vfx/impact_effect.tscn")
	assert_not_null(scene, "Cena impact_effect.tscn deve existir.")
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	
	var metal_sparks: GPUParticles3D = inst.get_node_or_null("MetalSparksParticles") as GPUParticles3D
	var dust_particles: GPUParticles3D = inst.get_node_or_null("DustParticles") as GPUParticles3D
	assert_not_null(metal_sparks, "impact_effect deve possuir particulas de faiscas metalicas.")
	assert_not_null(dust_particles, "impact_effect deve possuir particulas de poeira.")
	assert_true(metal_sparks.one_shot, "Faiscas devem ser configuradas com one_shot = true.")
	assert_true(dust_particles.one_shot, "Poeira deve ser configurada com one_shot = true.")
	
	# Testa discriminacao para superficie metalica
	var metal_target: Node3D = Node3D.new()
	metal_target.add_to_group("metal")
	add_child_autofree(metal_target)
	if inst.has_method("setup_for_target"):
		inst.setup_for_target(metal_target, Vector3(0, 1.0, 0))
		assert_true(metal_sparks.emitting, "Emissao de faiscas deve ser ativada para alvo metalico.")
	
	# Testa discriminacao para impacto no solo
	var ground_target: Node3D = Node3D.new()
	add_child_autofree(ground_target)
	if inst.has_method("setup_for_target"):
		inst.setup_for_target(ground_target, Vector3(0, 1.5, 0))
		assert_true(dust_particles.emitting, "Emissao de poeira deve ser ativada para solo.")


func test_water_splash_vertical_particles_and_lifecycle() -> void:
	var scene: PackedScene = load("res://scenes/vfx/water_splash.tscn")
	assert_not_null(scene, "Cena water_splash.tscn deve existir.")
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	
	var splash_particles: GPUParticles3D = inst.get_node_or_null("SplashParticles") as GPUParticles3D
	assert_not_null(splash_particles, "water_splash deve possuir no SplashParticles do tipo GPUParticles3D.")
	assert_true(splash_particles.one_shot, "SplashParticles deve ser one_shot = true.")
	
	var mat: ParticleProcessMaterial = splash_particles.process_material as ParticleProcessMaterial
	assert_not_null(mat, "SplashParticles deve possuir ParticleProcessMaterial.")
	assert_gt(mat.direction.y, 0.5, "Borrifo de agua deve possuir direcao vertical ascendente (Y > 0.5).")
	assert_lt(mat.gravity.y, 0.0, "Gotas de agua devem sofrer desaceleracao por gravidade (gravity.y < 0).")


func test_heavy_explosion_two_stages_and_gravity_debris() -> void:
	var scene: PackedScene = load("res://scenes/vfx/explosion_heavy.tscn")
	assert_not_null(scene, "Cena explosion_heavy.tscn deve existir.")
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	
	var flash_light: OmniLight3D = inst.get_node_or_null("FlashLight") as OmniLight3D
	var fireball_particles: GPUParticles3D = inst.get_node_or_null("FireballParticles") as GPUParticles3D
	var debris_particles: GPUParticles3D = inst.get_node_or_null("DebrisParticles") as GPUParticles3D
	
	assert_not_null(flash_light, "explosion_heavy deve conter clarao pontual (OmniLight3D).")
	assert_not_null(fireball_particles, "explosion_heavy deve conter bola de fogo volumetrica (FireballParticles).")
	assert_not_null(debris_particles, "explosion_heavy deve conter fragmentos/destrocos (DebrisParticles).")
	
	assert_true(fireball_particles.one_shot, "FireballParticles deve ser one_shot = true.")
	assert_true(debris_particles.one_shot, "DebrisParticles deve ser one_shot = true.")
	
	var debris_mat: ParticleProcessMaterial = debris_particles.process_material as ParticleProcessMaterial
	assert_not_null(debris_mat, "DebrisParticles deve ter ParticleProcessMaterial configurado.")
	assert_lt(debris_mat.gravity.y, 0.0, "Destrocos devem ter fisica de gravidade ativada (gravity.y < 0).")
