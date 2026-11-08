## Testes unitarios da tela de Hangar e aplicacao da meta-progressao permanente.
extends GutTest

const TEST_SAVE_PATH: String = "user://test_meta_progression.json"

var hangar: HangarScreen
var player: PlayerHelicopter


func before_each() -> void:
	MetaProgression.save_path = TEST_SAVE_PATH
	MetaProgression.reset_state()
	
	hangar = preload("res://scenes/roguelite/hangar_screen.tscn").instantiate()
	add_child_autofree(hangar)


func after_each() -> void:
	MetaProgression.reset_state()
	MetaProgression.save_path = MetaProgression.DEFAULT_SAVE_PATH
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func test_hangar_screen_initialization() -> void:
	assert_not_null(hangar.tokens_label, "Rotulo de tokens deve estar presente.")
	assert_eq(hangar.upgrade_resources.size(), 3, "Hangar deve gerenciar 3 upgrades permanentes.")
	assert_true(hangar.tokens_label.text.contains("0"), "Deve exibir saldo zero inicialmente.")


func test_purchase_upgrade_deducts_tokens_and_persists() -> void:
	MetaProgression.add_personnel_tokens(20)
	hangar.refresh_ui()
	
	watch_signals(hangar)
	var success: bool = hangar.purchase_upgrade_by_id("expand_cabin")
	
	assert_true(success, "Compra com saldo suficiente deve retornar True.")
	assert_eq(MetaProgression.get_upgrade_level("expand_cabin"), 1, "Nivel de expand_cabin deve subir para 1.")
	assert_eq(MetaProgression.personnel_tokens, 17, "20 tokens - 3 de custo deve restar 17.")
	assert_signal_emitted(hangar, "upgrade_purchased", "Deve emitir upgrade_purchased ao adquirir.")
	
	# Verifica que arquivo em disco foi atualizado
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH), "Arquivo de persistencia deve existir em disco.")
	var fresh_meta: Dictionary = {}
	var file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	if file != null:
		fresh_meta = JSON.parse_string(file.get_as_text())
		file.close()
	assert_eq(int(fresh_meta["personnel_tokens"]), 17, "Tokens salvos em disco devem ser 17.")
	assert_eq(int(fresh_meta["upgrade_levels"]["expand_cabin"]), 1, "Nivel salvo em disco deve ser 1.")


func test_purchase_with_insufficient_tokens_fails() -> void:
	MetaProgression.personnel_tokens = 1
	hangar.refresh_ui()
	
	var success: bool = hangar.purchase_upgrade_by_id("reinforce_armor")
	assert_false(success, "Compra com saldo insuficiente deve falhar.")
	assert_eq(MetaProgression.get_upgrade_level("reinforce_armor"), 0, "Nivel deve permanecer zero.")
	assert_eq(MetaProgression.personnel_tokens, 1, "Saldo nao deve ser deduzido.")


func test_player_helicopter_initializes_with_meta_upgrades() -> void:
	MetaProgression.upgrade_levels["expand_cabin"] = 1 # Capacidade: 6
	MetaProgression.upgrade_levels["reinforce_armor"] = 1 # Vida: 1100.0
	MetaProgression.upgrade_levels["ammo_logistics"] = 1 # Multiplicador: 1.2
	
	player = preload("res://scenes/entities/player/player_helicopter.tscn").instantiate()
	add_child_autofree(player)
	
	assert_eq(player.cargo_component.max_capacity, 6, "Capacidade da cabine deve iniciar em 6 com expand_cabin nivel 1.")
	assert_eq(player.health_component.max_health, 1100.0, "Vida maxima deve iniciar em 1100 com reinforce_armor nivel 1.")
	assert_eq(player.health_component.current_health, 1100.0, "Vida corrente deve iniciar cheia com 1100.")
	
	var vulcan_max: int = player.weapon_manager.weapon_slots[0].max_ammo
	assert_eq(vulcan_max, int(round(1200 * 1.2)), "Municao de Vulcan deve ter bonus de +20% (1440).")


func test_launch_button_starts_run() -> void:
	watch_signals(hangar)
	GameState.current_status = GameState.RunStatus.IDLE
	
	hangar.on_launch_pressed()
	
	assert_signal_emitted(hangar, "mission_launch_requested", "Deve emitir mission_launch_requested.")
	assert_eq(GameState.current_status, GameState.RunStatus.IN_PROGRESS, "GameState deve transicionar para IN_PROGRESS.")
