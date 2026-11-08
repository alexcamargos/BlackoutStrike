## Testes unitarios para o sistema de travamento de alvos em cone e missil teleguiado Hellfire.
extends GutTest

var projectile: Projectile
var target_scanner: TargetScanner
var host_entity: Node3D


func before_each() -> void:
	host_entity = Node3D.new()
	add_child_autofree(host_entity)
	
	target_scanner = TargetScanner.new()
	host_entity.add_child(target_scanner)
	
	projectile = Projectile.new()
	projectile.damage = 650.0
	projectile.speed = 50.0
	projectile.lifetime = 4.0
	projectile.is_homing = true
	projectile.homing_turn_speed = 6.0
	add_child_autofree(projectile)


func test_target_inside_cone_is_selected() -> void:
	var forward: Vector3 = Vector3(0, 0, -1)
	var origin: Vector3 = Vector3.ZERO
	
	var valid_enemy: Node3D = Node3D.new()
	add_child_autofree(valid_enemy)
	valid_enemy.global_position = Vector3(5, 0, -20) # Angulo de ~14 graus (< 20 graus de semi-cone)
	valid_enemy.add_to_group("enemies")
	
	var chosen_target: Node3D = target_scanner.find_best_target(origin, forward, 40.0, 50.0, [valid_enemy])
	assert_eq(chosen_target, valid_enemy, "O inimigo dentro do cone de 40 graus deve ser selecionado.")


func test_target_outside_cone_is_rejected() -> void:
	var forward: Vector3 = Vector3(0, 0, -1)
	var origin: Vector3 = Vector3.ZERO
	
	var outside_enemy: Node3D = Node3D.new()
	add_child_autofree(outside_enemy)
	outside_enemy.global_position = Vector3(20, 0, -10) # Angulo de ~63 graus (> 20 graus de semi-cone)
	outside_enemy.add_to_group("enemies")
	
	var chosen_target: Node3D = target_scanner.find_best_target(origin, forward, 40.0, 50.0, [outside_enemy])
	assert_null(chosen_target, "O inimigo fora do cone de 40 graus deve ser rejeitado.")


func test_closest_target_in_cone_has_priority() -> void:
	var forward: Vector3 = Vector3(0, 0, -1)
	var origin: Vector3 = Vector3.ZERO
	
	var far_enemy: Node3D = Node3D.new()
	add_child_autofree(far_enemy)
	far_enemy.global_position = Vector3(2, 0, -35)
	far_enemy.add_to_group("enemies")
	
	var near_enemy: Node3D = Node3D.new()
	add_child_autofree(near_enemy)
	near_enemy.global_position = Vector3(2, 0, -15)
	near_enemy.add_to_group("enemies")
	
	var chosen: Node3D = target_scanner.find_best_target(origin, forward, 40.0, 50.0, [far_enemy, near_enemy])
	assert_eq(chosen, near_enemy, "O alvo mais proximo dentro do cone deve ter prioridade de travamento.")


func test_missile_curves_towards_locked_target() -> void:
	var target: Node3D = Node3D.new()
	add_child_autofree(target)
	target.global_position = Vector3(10.0, 0.0, -20.0)
	
	projectile.global_position = Vector3(0.0, 0.0, 0.0)
	projectile.transform.basis = Basis.IDENTITY # Aponta para -Z
	projectile.homing_target = target
	
	# Simula 0.5s de avanco
	projectile.simulate_step(0.5)
	
	# O projetil deve ter se curvado lateralmente na direcao +X do alvo
	assert_gt(projectile.global_position.x, 0.0, "O missil deve virar na direcao X positiva em direcao ao alvo.")
	assert_lt(projectile.global_position.z, 0.0, "O missil deve continuar avancando no eixo Z.")


func test_missile_flies_straight_without_target() -> void:
	projectile.global_position = Vector3.ZERO
	projectile.transform.basis = Basis.IDENTITY
	projectile.homing_target = null
	
	projectile.simulate_step(0.5)
	
	assert_almost_eq(projectile.global_position.x, 0.0, 0.01, "Sem alvo travado, o projetil nao deve sofrer desvio em X.")
	assert_almost_eq(projectile.global_position.z, -25.0, 0.05, "O projetil deve avancar 25 metros retos no eixo -Z.")


func test_hellfire_scene_instantiates_correctly() -> void:
	var scene_res: PackedScene = load("res://scenes/weapons/projectile_hellfire.tscn")
	assert_not_null(scene_res, "A cena projectile_hellfire.tscn deve existir.")
	var instance: Projectile = scene_res.instantiate() as Projectile
	assert_not_null(instance, "A instancia deve ser do tipo Projectile.")
	assert_eq(instance.damage, 650.0, "Dano do Hellfire deve ser 650.0.")
	assert_true(instance.is_homing, "Hellfire deve possuir is_homing = true.")
	assert_eq(instance.explosion_radius, 2.5, "Raio de explosao do Hellfire deve ser 2.5m.")
	add_child_autofree(instance)
