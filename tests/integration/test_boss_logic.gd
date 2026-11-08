extends GutTest

var boss: BossApexBastion

func before_each() -> void:
	var boss_scene: PackedScene = load("res://scenes/entities/enemies/boss_apex_bastion.tscn") as PackedScene
	boss = boss_scene.instantiate() as BossApexBastion
	add_child_autofree(boss)

func test_core_is_invulnerable_while_turrets_are_active() -> void:
	var initial_core_hp: float = boss.core_health.current_health
	assert_eq(initial_core_hp, 2400.0, "O nucleo deve iniciar com 2400 HP.")
	boss.damage_core(100.0)
	assert_eq(boss.core_health.current_health, initial_core_hp, "O reator central nao deve receber dano com as torretas intactas.")

func test_core_takes_damage_after_at_least_one_turret_falls() -> void:
	boss.bow_turret.health.take_damage(9999.0) # Destroi a torreta frontal
	assert_true(boss.bow_turret.is_destroyed(), "A torreta frontal deve estar destruida.")
	
	boss.take_damage(100.0) # Valida despacho via take_damage padrão de entidade
	assert_lt(boss.core_health.current_health, boss.core_health.max_health, "O reator deve ficar vulneravel apos a queda da primeira torreta.")
	assert_eq(boss.core_health.current_health, 2300.0, "Deve descontar exatamente 100 de dano do reator.")

func test_boss_transitions_to_phase_two_at_forty_nine_percent() -> void:
	watch_signals(boss)
	boss.stern_turret.health.take_damage(9999.0) # Destroi a segunda torreta
	
	# 2400 * 0.49 = 1176. Reduzindo 1300 HP leva a vida para 1100 (45.8%)
	boss.damage_core(1300.0)
	assert_eq(boss.current_phase, 2, "Ao ficar abaixo de 49% HP, deve transitar para a Fase 2.")
	assert_signal_emitted(boss, "phase_changed", "Deve emitir o sinal de mudanca de fase.")

func test_core_destruction_emits_boss_defeated_and_mission_accomplished() -> void:
	watch_signals(boss)
	watch_signals(EventBus)
	
	boss.bow_turret.health.take_damage(9999.0)
	boss.damage_core(3000.0) # Esgota o nucleo de 2400 HP
	
	assert_signal_emitted(boss, "boss_defeated", "Deve emitir boss_defeated local.")
	assert_signal_emitted(EventBus, "boss_defeated", "EventBus deve emitir boss_defeated.")
	assert_signal_emitted(EventBus, "mission_accomplished", "EventBus deve emitir mission_accomplished.")
	assert_true(boss.is_queued_for_deletion(), "O chefe deve ser desalocado da arvore ao morrer.")

func test_boss_phase_attacks_and_mine_dropping_without_errors() -> void:
	# Valida lancamento de minas e canhoes da Fase 1 sem lancar erros de !is_inside_tree()
	boss._drop_naval_mine()
	boss._fire_double_cannon()
	
	# Valida ataques da Fase 2
	boss._fire_ciws_fan()
	boss._fire_missile_salvo()
	
	assert_true(boss.is_inside_tree(), "O chefe deve permanecer estavel e funcional na arvore.")


func test_boss_naval_modular_model_structure() -> void:
	# Casco com linha de flutuacao
	var hull: Node3D = boss.get_node_or_null("HullStaticBody/ModelContainer/MainHull") as Node3D
	assert_not_null(hull, "O chefe deve possuir malha principal de casco naval.")
	var waterline: Node3D = boss.get_node_or_null("HullStaticBody/ModelContainer/WaterlineTrim") as Node3D
	assert_not_null(waterline, "O casco deve possuir detalhe de linha de flutuacao.")
	
	# Torreta de proa com canhao duplo 76mm
	var bow_barbette: Node3D = boss.get_node_or_null("BowTurret/TurretBarbette") as Node3D
	assert_not_null(bow_barbette, "Torreta de proa deve possuir barbete de sustentacao.")
	var bow_barrel_l: Node3D = boss.get_node_or_null("BowTurret/BarrelLeft") as Node3D
	var bow_barrel_r: Node3D = boss.get_node_or_null("BowTurret/BarrelRight") as Node3D
	assert_not_null(bow_barrel_l, "Torreta de proa deve possuir canhao esquerdo 76mm.")
	assert_not_null(bow_barrel_r, "Torreta de proa deve possuir canhao direito 76mm.")
	
	# Torreta de popa com CIWS quad
	var stern_barbette: Node3D = boss.get_node_or_null("SternTurret/TurretBarbette") as Node3D
	assert_not_null(stern_barbette, "Torreta de popa deve possuir barbete.")
	var quad_barrels: Node3D = boss.get_node_or_null("SternTurret/QuadBarrels") as Node3D
	assert_not_null(quad_barrels, "Torreta de popa deve possuir canos quadruplos CIWS.")
	
	# Nucleo central com blindagem retratil
	var left_armor: Node3D = boss.get_node_or_null("CoreBridge/RetractableArmorLeft") as Node3D
	var right_armor: Node3D = boss.get_node_or_null("CoreBridge/RetractableArmorRight") as Node3D
	var reactor: MeshInstance3D = boss.get_node_or_null("CoreBridge/CoreReactorMesh") as MeshInstance3D
	assert_not_null(left_armor, "Nucleo deve conter blindagem retratil esquerda.")
	assert_not_null(right_armor, "Nucleo deve conter blindagem retratil direita.")
	assert_not_null(reactor, "Nucleo deve conter malha do reator central.")


func test_turret_destruction_applies_damaged_material() -> void:
	var bow_house: MeshInstance3D = boss.get_node_or_null("BowTurret/TurretHouse") as MeshInstance3D
	assert_not_null(bow_house, "Deve encontrar TurretHouse na proa.")
	
	# Destroi a torreta de proa
	boss.bow_turret.health.take_damage(9999.0)
	assert_true(boss.bow_turret.is_destroyed(), "Torreta de proa deve ser dada como destruida.")
	
	# Verifica se o material de superficie foi alterado para danificado/carbonizado
	var override_mat: StandardMaterial3D = bow_house.get_surface_override_material(0) as StandardMaterial3D
	assert_not_null(override_mat, "A malha da torreta destruida deve receber material de override danificado.")
	assert_true(override_mat.roughness >= 0.8, "Material avariado deve apresentar alta rugosidade (>= 0.8).")
	assert_true(override_mat.albedo_color.r <= 0.15, "Albedo do material danificado deve ser escurecido/carbonizado.")


func test_phase_two_retracts_armor_and_activates_pulse() -> void:
	var left_armor: Node3D = boss.get_node_or_null("CoreBridge/RetractableArmorLeft") as Node3D
	var right_armor: Node3D = boss.get_node_or_null("CoreBridge/RetractableArmorRight") as Node3D
	var initial_x_left: float = left_armor.position.x
	var initial_x_right: float = right_armor.position.x
	
	# Destroi uma torreta e reduz HP para forcar Fase 2
	boss.bow_turret.health.take_damage(9999.0)
	boss.damage_core(1300.0) # Entra na Fase 2 (< 49% HP)
	assert_eq(boss.current_phase, 2, "Chefe deve estar na Fase 2.")
	
	# Placas de blindagem devem ter recuado para as laterais
	assert_true(left_armor.position.x < initial_x_left, "Blindagem esquerda deve retrair abrindo para o exterior.")
	assert_true(right_armor.position.x > initial_x_right, "Blindagem direita deve retrair abrindo para o exterior.")
	
	# Reator deve estar com pulso emissivo ativo em alta energia
	var reactor: MeshInstance3D = boss.get_node_or_null("CoreBridge/CoreReactorMesh") as MeshInstance3D
	var mat: StandardMaterial3D = reactor.mesh.material as StandardMaterial3D
	assert_true(mat.emission_enabled, "Emissao do reator deve estar ativada na Fase 2.")
	assert_true(mat.emission_energy_multiplier >= 4.0, "Multiplicador de emissao deve atingir nivel HDR de pulso (>= 4.0).")

