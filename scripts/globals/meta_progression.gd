## Gerenciador global de meta-progressao permanente e persistencia do Hangar.
##
## Controla o saldo de Personnel Tokens obtidos através da extracao de civis
## e armazena os niveis de melhorias em disco em formato JSON.
extends Node

## Caminho do arquivo de persistencia local.
const SAVE_PATH: String = "user://meta_progression.json"

## Saldo de fichas de pessoal para compras no Hangar.
var personnel_tokens: int = 0

## Niveis atuais das melhorias do Hangar.
var upgrade_levels: Dictionary = {
	"expand_cabin": 0,
	"reinforce_armor": 0,
	"ammo_logistics": 0
}


func _ready() -> void:
	load_from_disk()


## Adiciona tokens de pessoal e persiste a alteracao em disco.
##
## Args:
##     amount (int): Quantidade de tokens a adicionar (deve ser positiva).
##
## Returns:
##     void
func add_personnel_tokens(amount: int) -> void:
	if amount <= 0:
		return
	personnel_tokens += amount
	save_to_disk()


## Verifica se o jogador possui saldo e nivel compativel para o upgrade.
##
## Args:
##     upgrade (HangarUpgradeData): Recurso com configuracoes do aprimoramento.
##
## Returns:
##     bool: True se o upgrade pode ser adquirido; False caso contrario.
func can_afford_upgrade(upgrade: HangarUpgradeData) -> bool:
	if upgrade == null:
		return false
	var current_lvl: int = get_upgrade_level(upgrade.id)
	if current_lvl >= upgrade.max_level:
		return false
	if current_lvl >= upgrade.cost_per_level.size():
		return false
	var cost: int = upgrade.cost_per_level[current_lvl]
	return personnel_tokens >= cost


## Adquire o upgrade informado deduzindo o custo e incrementando o nivel.
##
## Args:
##     upgrade (HangarUpgradeData): Recurso com dados do upgrade a comprar.
##
## Returns:
##     bool: True se a transacao foi completada com sucesso; False em caso de falha.
func purchase_upgrade(upgrade: HangarUpgradeData) -> bool:
	if not can_afford_upgrade(upgrade):
		return false
	var current_lvl: int = get_upgrade_level(upgrade.id)
	var cost: int = upgrade.cost_per_level[current_lvl]
	personnel_tokens -= cost
	upgrade_levels[upgrade.id] = current_lvl + 1
	save_to_disk()
	return true


## Retorna o nivel atual de uma melhoria pelo seu identificador unico.
##
## Args:
##     upgrade_id (String): Chave identificadora do upgrade.
##
## Returns:
##     int: Nivel atual registrado ou 0 caso nao exista.
func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


## Salva os dados de meta-progressao no arquivo JSON em disco.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func save_to_disk() -> void:
	var payload: Dictionary = {
		"personnel_tokens": personnel_tokens,
		"upgrade_levels": upgrade_levels
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		var json_string: String = JSON.stringify(payload, "\t")
		file.store_string(json_string)
		file.close()


## Carrega os dados de meta-progressao persistidos em disco.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var content: String = file.get_as_text()
	file.close()
	
	var parsed: Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		var data: Dictionary = parsed as Dictionary
		if data.has("personnel_tokens"):
			personnel_tokens = int(data["personnel_tokens"])
		if data.has("upgrade_levels") and data["upgrade_levels"] is Dictionary:
			var loaded_upgrades: Dictionary = data["upgrade_levels"] as Dictionary
			for key: String in loaded_upgrades:
				upgrade_levels[key] = int(loaded_upgrades[key])
