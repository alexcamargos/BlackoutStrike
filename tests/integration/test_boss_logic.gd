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
