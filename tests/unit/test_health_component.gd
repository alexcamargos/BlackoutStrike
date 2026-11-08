extends GutTest

## Bateria de testes unitarios para o componente de saude e blindagem (HealthComponent).

var health: HealthComponent


func before_each() -> void:
	health = HealthComponent.new()
	health.max_health = 1000.0
	health.current_health = 1000.0
	add_child_autofree(health)


func test_health_initial_state() -> void:
	var fresh_health: HealthComponent = HealthComponent.new()
	add_child_autofree(fresh_health)
	assert_eq(fresh_health.max_health, 1000.0, "A vida maxima padrao deve ser 1000.0.")
	assert_eq(fresh_health.current_health, 1000.0, "A vida atual padrao deve ser 1000.0.")
	assert_false(fresh_health.is_invulnerable, "A entidade nao deve ser invulneravel por padrao.")
	assert_false(fresh_health.is_destroyed(), "Componente recem-instanciado nao deve estar destruido.")


func test_damage_reduces_health_and_emits_signal() -> void:
	watch_signals(health)
	health.take_damage(250.0)
	assert_almost_eq(health.current_health, 750.0, 0.01, "O dano deve reduzir a vida de forma precisa.")
	assert_signal_emitted(health, "health_changed", "Deve emitir health_changed ao sofrer dano.")


func test_damage_clamps_at_zero_and_emits_destroyed() -> void:
	watch_signals(health)
	health.take_damage(1200.0)
	assert_eq(health.current_health, 0.0, "A vida nao deve ficar abaixo de zero.")
	assert_signal_emitted(health, "entity_destroyed", "Deve emitir entity_destroyed ao zerar HP.")
	assert_true(health.is_destroyed(), "is_destroyed() deve retornar true com vida zerada.")


func test_repair_increases_health_and_emits_signal() -> void:
	health.take_damage(400.0)
	watch_signals(health)
	health.repair(150.0)
	assert_almost_eq(health.current_health, 750.0, 0.01, "Reparo deve acrescentar pontos de vida.")
	assert_signal_emitted(health, "health_changed", "Deve emitir health_changed ao reparar.")


func test_repair_does_not_exceed_max_health() -> void:
	health.take_damage(200.0)
	health.repair(500.0)
	assert_eq(health.current_health, 1000.0, "O reparo nao pode ultrapassar o teto de max_health.")


func test_invulnerable_entity_ignores_damage() -> void:
	health.is_invulnerable = true
	watch_signals(health)
	health.take_damage(500.0)
	assert_eq(health.current_health, 1000.0, "Entidade invulneravel nao deve sofrer dano.")
	assert_signal_not_emitted(health, "health_changed", "Nao deve emitir health_changed para entidade invulneravel.")
	assert_signal_not_emitted(health, "entity_destroyed", "Nao deve emitir entity_destroyed para entidade invulneravel.")


func test_non_positive_damage_is_ignored() -> void:
	watch_signals(health)
	health.take_damage(0.0)
	health.take_damage(-50.0)
	assert_eq(health.current_health, 1000.0, "Valores nao positivos de dano devem ser ignorados.")
	assert_signal_not_emitted(health, "health_changed", "Nao deve emitir sinal para dano invalido.")


func test_non_positive_repair_is_ignored() -> void:
	health.take_damage(300.0)
	watch_signals(health)
	health.repair(0.0)
	health.repair(-50.0)
	assert_eq(health.current_health, 700.0, "Valores nao positivos de reparo devem ser ignorados.")
	assert_signal_not_emitted(health, "health_changed", "Nao deve emitir sinal para reparo invalido.")


func test_already_destroyed_entity_does_not_retrigger_destroyed_signal() -> void:
	health.take_damage(1000.0)
	assert_true(health.is_destroyed())
	watch_signals(health)
	health.take_damage(100.0)
	assert_signal_not_emitted(health, "entity_destroyed", "Nao deve reemitir entity_destroyed se ja estiver destruido.")
