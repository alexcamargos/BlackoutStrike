## Testes unitarios para o gerenciador de armas, slots, cadencia e estoque de municao.
extends GutTest

var weapon_mgr: WeaponManager
var vulcan_data: WeaponData
var hydra_data: WeaponData
var hellfire_data: WeaponData


func before_each() -> void:
	weapon_mgr = WeaponManager.new()
	
	vulcan_data = WeaponData.new()
	vulcan_data.id = "vulcan_20mm"
	vulcan_data.display_name = "Canhao Rotativo Vulcan"
	vulcan_data.max_ammo = 1200
	vulcan_data.fire_rate = 12.0 # Cooldown = 1/12 s
	vulcan_data.base_damage = 14.0
	vulcan_data.projectile_speed = 120.0
	
	hydra_data = WeaponData.new()
	hydra_data.id = "hydra_70"
	hydra_data.display_name = "Foguetes Hydra 70"
	hydra_data.max_ammo = 32
	hydra_data.fire_rate = 2.0
	hydra_data.base_damage = 160.0
	hydra_data.explosion_radius = 3.0
	
	hellfire_data = WeaponData.new()
	hellfire_data.id = "hellfire_agm"
	hellfire_data.display_name = "Missil Hellfire"
	hellfire_data.max_ammo = 6
	hellfire_data.fire_rate = 1.0
	hellfire_data.base_damage = 650.0
	hellfire_data.is_homing = true
	
	weapon_mgr.weapon_slots = [vulcan_data, hydra_data, hellfire_data]
	add_child_autofree(weapon_mgr)


func test_initial_ammo_setup() -> void:
	assert_eq(weapon_mgr.ammo_counts.size(), 3, "Devem existir 3 contadores de municao.")
	assert_eq(weapon_mgr.ammo_counts[0], 1200, "Municao inicial do Vulcan deve ser 1200.")
	assert_eq(weapon_mgr.ammo_counts[1], 32, "Municao inicial do Hydra deve ser 32.")
	assert_eq(weapon_mgr.ammo_counts[2], 6, "Municao inicial do Hellfire deve ser 6.")
	assert_eq(weapon_mgr.get_current_ammo(), 1200, "Municao ativa no slot 0 deve ser 1200.")


func test_fire_reduces_ammo_and_emits_signals() -> void:
	watch_signals(weapon_mgr)
	var fired: bool = weapon_mgr.try_fire(Transform3D.IDENTITY)
	
	assert_true(fired, "O primeiro disparo com municao cheia deve ser bem-sucedido.")
	assert_eq(weapon_mgr.get_current_ammo(), 1199, "A municao deve decrementar em 1 unidade.")
	assert_signal_emitted(weapon_mgr, "ammo_updated", "O sinal ammo_updated deve ser emitido.")


func test_cannot_fire_with_zero_ammo() -> void:
	weapon_mgr.ammo_counts[0] = 0
	var fired: bool = weapon_mgr.try_fire(Transform3D.IDENTITY)
	
	assert_false(fired, "Nao deve ser possivel disparar com municao esgotada.")
	assert_eq(weapon_mgr.get_current_ammo(), 0, "A contagem deve permanecer zero.")


func test_fire_rate_cooldown_enforcement() -> void:
	var first_shot: bool = weapon_mgr.try_fire(Transform3D.IDENTITY)
	assert_true(first_shot, "Primeiro tiro disparado com sucesso.")
	
	# Tentativa imediata sem tempo decorrido deve falhar
	var immediate_shot: bool = weapon_mgr.try_fire(Transform3D.IDENTITY)
	assert_false(immediate_shot, "Disparo repetido antes do tempo de cadencia deve ser bloqueado.")
	
	# Avanco do tempo fisico simulado
	weapon_mgr._process(1.0 / 12.0 + 0.01)
	var next_shot: bool = weapon_mgr.try_fire(Transform3D.IDENTITY)
	assert_true(next_shot, "Disparo apos o termino do cooldown deve ser autorizado.")


func test_slot_selection_and_cycling() -> void:
	watch_signals(weapon_mgr)
	
	weapon_mgr.select_slot(1)
	assert_eq(weapon_mgr.current_slot_index, 1, "Slot ativo deve ser o 1 (Hydra).")
	assert_eq(weapon_mgr.get_current_ammo(), 32, "Municao atual deve refletir o slot selecionado.")
	assert_signal_emitted(weapon_mgr, "weapon_switched", "Sinal weapon_switched deve ser emitido.")
	
	weapon_mgr.cycle_next_slot()
	assert_eq(weapon_mgr.current_slot_index, 2, "Proximo slot ciclado deve ser o 2 (Hellfire).")
	
	weapon_mgr.cycle_next_slot()
	assert_eq(weapon_mgr.current_slot_index, 0, "Ciclo deve retornar ao slot inicial 0 (Vulcan).")


func test_replenish_ammo_fraction() -> void:
	weapon_mgr.ammo_counts[0] = 600 # 50%
	weapon_mgr.ammo_counts[1] = 16  # 50%
	weapon_mgr.ammo_counts[2] = 2   # 33%
	
	weapon_mgr.replenish_ammo_fraction(0.25) # +25%
	
	# Vulcan: 600 + 300 = 900
	assert_eq(weapon_mgr.ammo_counts[0], 900, "Vulcan deve recuperar 25% da capacidade maxima (+300).")
	# Hydra: 16 + 8 = 24
	assert_eq(weapon_mgr.ammo_counts[1], 24, "Hydra deve recuperar 25% (+8).")
	# Hellfire: 2 + round(6 * 0.25 = 1.5 -> 2) = 4
	assert_eq(weapon_mgr.ammo_counts[2], 4, "Hellfire deve recuperar cerca de 2 mísseis.")


func test_replenish_ammo_clamps_at_max() -> void:
	weapon_mgr.ammo_counts[0] = 1150
	weapon_mgr.replenish_ammo_fraction(0.25) # Tentaria somar +300
	assert_eq(weapon_mgr.ammo_counts[0], 1200, "A contagem nao pode ultrapassar o teto de max_ammo.")
