## Testes unitarios para o sistema modular de projeteis e balistica.
extends GutTest

var projectile: Projectile
var dummy_target: StaticBody3D
var dummy_health: HealthComponent


func before_each() -> void:
	projectile = Projectile.new()
	projectile.damage = 25.0
	projectile.speed = 100.0
	projectile.lifetime = 2.0
	projectile.explosion_radius = 0.0
	projectile.pierce_remaining = 0
	add_child_autofree(projectile)
	
	dummy_target = StaticBody3D.new()
	dummy_health = HealthComponent.new()
	dummy_health.max_health = 100.0
	dummy_health.current_health = 100.0
	dummy_target.add_child(dummy_health)
	add_child_autofree(dummy_target)


func test_projectile_moves_forward() -> void:
	projectile.global_position = Vector3(0, 0, 0)
	projectile.transform.basis = Basis.IDENTITY
	
	projectile.simulate_step(0.1)
	
	# No Godot 3D, a frente padrao e o eixo -Z
	assert_almost_eq(projectile.global_position.z, -10.0, 0.05, "O projetil deve avancar na direcao -Z.")
	assert_almost_eq(projectile.global_position.x, 0.0, 0.01, "O projetil nao deve sofrer desvio lateral sem dispersao.")


func test_projectile_despawns_after_lifetime() -> void:
	projectile.simulate_step(1.5)
	assert_false(projectile.is_queued_for_deletion(), "O projetil nao deve ser desalocado antes de expirar a vida util.")
	
	projectile.simulate_step(0.6)
	assert_true(projectile.is_queued_for_deletion(), "O projetil deve ser enfileirado para remocao ao ultrapassar a vida util.")


func test_projectile_deals_direct_damage_on_impact() -> void:
	projectile.handle_hit(dummy_target)
	
	assert_eq(dummy_health.current_health, 75.0, "O alvo deve receber o dano nominal do projetil.")
	assert_true(projectile.is_queued_for_deletion(), "O projetil deve ser desalocado apos o impacto sem perfuracao.")


func test_projectile_ignores_source_node() -> void:
	var shooter: CharacterBody3D = CharacterBody3D.new()
	var shooter_health: HealthComponent = HealthComponent.new()
	shooter_health.max_health = 500.0
	shooter_health.current_health = 500.0
	shooter.add_child(shooter_health)
	add_child_autofree(shooter)
	
	projectile.source = shooter
	projectile.handle_hit(shooter)
	
	assert_eq(shooter_health.current_health, 500.0, "O atirador nao deve sofrer dano do proprio disparo.")
	assert_false(projectile.is_queued_for_deletion(), "O projetil nao deve detonar ao colidir com o atirador.")


func test_projectile_pierce_preserves_instance_on_first_hit() -> void:
	projectile.pierce_remaining = 1
	
	projectile.handle_hit(dummy_target)
	assert_eq(dummy_health.current_health, 75.0, "O primeiro alvo atingido deve sofrer dano.")
	assert_false(projectile.is_queued_for_deletion(), "O projetil nao deve ser destruido no primeiro impacto com perfuracao ativa.")
	assert_eq(projectile.pierce_remaining, 0, "O contador de perfuracoes restantes deve decrementar.")
	
	# Segundo impacto apos esgotar a perfuracao
	var second_target: StaticBody3D = StaticBody3D.new()
	var second_health: HealthComponent = HealthComponent.new()
	second_health.max_health = 100.0
	second_health.current_health = 100.0
	second_target.add_child(second_health)
	add_child_autofree(second_target)
	
	projectile.handle_hit(second_target)
	assert_eq(second_health.current_health, 75.0, "O segundo alvo deve sofrer dano.")
	assert_true(projectile.is_queued_for_deletion(), "O projetil deve ser desalocado apos consumir a ultima perfuracao.")


func test_projectile_applies_structure_damage_bonus() -> void:
	dummy_target.add_to_group("structures")
	projectile.structure_damage_bonus = 0.25 # +25%
	
	projectile.handle_hit(dummy_target)
	# Dano base: 25.0 * (1.0 + 0.25) = 31.25 -> 100.0 - 31.25 = 68.75
	assert_almost_eq(dummy_health.current_health, 68.75, 0.01, "O dano contra alvos do grupo structures deve receber o bonus.")


func test_vulcan_and_hydra_scenes_instantiate_correctly() -> void:
	var vulcan_scene: PackedScene = load("res://scenes/weapons/projectile_vulcan.tscn")
	assert_not_null(vulcan_scene, "A cena de projetil do Vulcan deve existir.")
	var vulcan_inst: Projectile = vulcan_scene.instantiate() as Projectile
	assert_not_null(vulcan_inst, "A instancia do Vulcan deve ser do tipo Projectile.")
	assert_eq(vulcan_inst.damage, 14.0, "Dano do Vulcan deve ser 14.0.")
	assert_eq(vulcan_inst.speed, 120.0, "Velocidade do Vulcan deve ser 120.0 m/s.")
	add_child_autofree(vulcan_inst)
	
	var hydra_scene: PackedScene = load("res://scenes/weapons/projectile_hydra.tscn")
	assert_not_null(hydra_scene, "A cena de foguete Hydra deve existir.")
	var hydra_inst: Projectile = hydra_scene.instantiate() as Projectile
	assert_not_null(hydra_inst, "A instancia do Hydra deve ser do tipo Projectile.")
	assert_eq(hydra_inst.damage, 160.0, "Dano do Hydra deve ser 160.0.")
	assert_eq(hydra_inst.explosion_radius, 3.0, "Raio de explosao do Hydra deve ser 3.0 m.")
	add_child_autofree(hydra_inst)

