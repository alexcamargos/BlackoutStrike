## Testes de integridade e carregamento dos schemas de dados e recursos CustomResource.
extends GutTest

const WEAPON_PATHS: Array[String] = [
	"res://scripts/data/weapon_vulcan.tres",
	"res://scripts/data/weapon_hydra.tres",
	"res://scripts/data/weapon_hellfire.tres",
]

const BOON_PATHS: Array[String] = [
	"res://scripts/data/boon_overclock_rotor.tres",
	"res://scripts/data/boon_armor_piercing_ammo.tres",
	"res://scripts/data/boon_high_power_winch.tres",
	"res://scripts/data/boon_auxiliary_fuel_tanks.tres",
	"res://scripts/data/boon_chaff_flare_system.tres",
]

const UPGRADE_PATHS: Array[String] = [
	"res://scripts/data/upgrade_expand_cabin.tres",
	"res://scripts/data/upgrade_reinforce_armor.tres",
	"res://scripts/data/upgrade_ammo_logistics.tres",
]

const ENEMY_PATHS: Array[String] = [
	"res://scripts/data/enemy_mercenary_squad.tres",
	"res://scripts/data/enemy_hunter_drone.tres",
	"res://scripts/data/enemy_patrol_boat.tres",
	"res://scripts/data/enemy_light_tank.tres",
	"res://scripts/data/enemy_turret_sam.tres",
	"res://scripts/data/data_crate.tres",
]

func test_weapon_resources_load_correctly() -> void:
	for path in WEAPON_PATHS:
		var res: Resource = ResourceLoader.load(path)
		assert_not_null(res, "Recurso de arma deve carregar: %s" % path)
		assert_true(res is WeaponData, "Deve ser instancia de WeaponData: %s" % path)
		var weapon: WeaponData = res as WeaponData
		assert_gt(weapon.id.length(), 0, "ID da arma nao pode ser vazio: %s" % path)
		assert_gt(weapon.base_damage, 0.0, "Dano base deve ser positivo: %s" % path)
		assert_gt(weapon.max_ammo, 0, "Municao maxima deve ser positiva: %s" % path)

func test_boon_resources_load_correctly() -> void:
	for path in BOON_PATHS:
		var res: Resource = ResourceLoader.load(path)
		assert_not_null(res, "Recurso de boon deve carregar: %s" % path)
		assert_true(res is BoonData, "Deve ser instancia de BoonData: %s" % path)
		var boon: BoonData = res as BoonData
		assert_gt(boon.id.length(), 0, "ID do boon nao pode ser vazio: %s" % path)
		assert_gt(boon.title.length(), 0, "Titulo do boon nao pode ser vazio: %s" % path)
		assert_gt(boon.target_property_name.length(), 0, "Propriedade alvo deve ser especificada: %s" % path)

func test_hangar_upgrade_resources_load_correctly() -> void:
	for path in UPGRADE_PATHS:
		var res: Resource = ResourceLoader.load(path)
		assert_not_null(res, "Recurso de upgrade deve carregar: %s" % path)
		assert_true(res is HangarUpgradeData, "Deve ser instancia de HangarUpgradeData: %s" % path)
		var up: HangarUpgradeData = res as HangarUpgradeData
		assert_gt(up.id.length(), 0, "ID do upgrade nao pode ser vazio: %s" % path)
		assert_eq(up.cost_per_level.size(), up.max_level, "Deve ter custos para todos os niveis: %s" % path)
		assert_eq(up.value_per_level.size(), up.max_level, "Deve ter valores para todos os niveis: %s" % path)

func test_helicopter_specs_load_correctly() -> void:
	var path: String = "res://scripts/data/helicopter_specs.tres"
	var res: Resource = ResourceLoader.load(path)
	assert_not_null(res, "Specs do helicoptero devem carregar.")
	assert_true(res is HelicopterSpecsData, "Deve ser instancia de HelicopterSpecsData.")
	var specs: HelicopterSpecsData = res as HelicopterSpecsData
	assert_eq(specs.max_armor, 1000.0, "Armor maxima deve ser 1000.")
	assert_eq(specs.max_fuel, 100.0, "Combustivel maximo deve ser 100.")
	assert_eq(specs.max_cargo, 5, "Carga maxima deve ser 5.")
	assert_gt(specs.acceleration, 0.0, "Aceleracao deve ser positiva.")
	assert_gt(specs.max_speed, 0.0, "Velocidade maxima deve ser positiva.")

func test_shelter_specs_load_correctly() -> void:
	var path: String = "res://scripts/data/rescue_shelter.tres"
	var res: Resource = ResourceLoader.load(path)
	assert_not_null(res, "Recurso de abrigo deve carregar.")
	assert_true(res is ShelterData, "Deve ser instancia de ShelterData.")
	var shelter: ShelterData = res as ShelterData
	assert_eq(shelter.max_health, 300.0, "Vida do abrigo deve ser 300.")
	assert_eq(shelter.survivor_count, 4, "Deve abrigar 4 sobreviventes.")
	assert_eq(shelter.survivor_max_health, 30.0, "Vida de sobrevivente deve ser 30.")

func test_enemy_stats_load_correctly() -> void:
	for path in ENEMY_PATHS:
		var res: Resource = ResourceLoader.load(path)
		assert_not_null(res, "Recurso de inimigo deve carregar: %s" % path)
		assert_true(res is EnemyStatsData, "Deve ser instancia de EnemyStatsData: %s" % path)
		var enemy: EnemyStatsData = res as EnemyStatsData
		assert_gt(enemy.id.length(), 0, "ID do inimigo nao pode ser vazio: %s" % path)
		assert_gt(enemy.max_health, 0.0, "HP do inimigo deve ser positivo: %s" % path)
