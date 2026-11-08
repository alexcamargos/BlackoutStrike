## Entidade coletavel de suprimento de campo (Caixa de Municao ou Tambor de Combustivel).
##
## Restaura recursos da aeronave do jogador por contato fisico ou rasante no raio de 3.0m.
## AmmoCrate restaura 25% da municao de todos os slots; FuelDrum restaura +30.0 de combustivel.
class_name SupplyPickup
extends Area3D

## Tipos de suprimentos disponiveis para drop em campo.
enum PickupType {
	AMMO_CRATE,
	FUEL_DRUM
}

## Sinal emitido no instante em que o suprimento e resgatado pelo jogador.
signal collected(type: PickupType)

## Tipo do suprimento instanciado.
@export var pickup_type: PickupType = PickupType.AMMO_CRATE

## Fracao de reposicao de municao para todos os slots (padrao: 0.25 = +25%).
@export var ammo_fraction: float = 0.25

## Quantidade de combustivel restaurado pelo tambor (padrao: +30.0).
@export var fuel_amount: float = 30.0

## Raio de alcance efetivo da coleta em metros.
@export var pickup_radius: float = 3.0

## Referencia a malha visual do item coletavel.
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

## Flag para prevenir coletas multiplas no mesmo frame.
var is_collected: bool = false


## Inicializa as camadas fisicas e configura o aspecto visual conforme o tipo de item.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	collision_layer = 128 # Camada 8 = Zones_Trigger
	collision_mask = 2    # Camada 2 = Player_Air
	
	body_entered.connect(_on_body_entered)
	_apply_visual_styling()


## Processa a coleta do suprimento pela aeronave do jogador.
##
## Args:
##     player (Node): Entidade da aeronave que acionou o item.
##
## Returns:
##     bool: True se a coleta foi concluida com sucesso; False caso contrario.
func collect(player: Node) -> bool:
	if is_collected or player == null:
		return false
	
	is_collected = true
	
	match pickup_type:
		PickupType.AMMO_CRATE:
			var weapon_mgr: WeaponManager = _find_weapon_manager(player)
			if weapon_mgr != null:
				weapon_mgr.replenish_ammo_fraction(ammo_fraction)
		PickupType.FUEL_DRUM:
			var fuel_comp: FuelComponent = _find_fuel_component(player)
			if fuel_comp != null:
				fuel_comp.refuel(fuel_amount)
	
	collected.emit(pickup_type)
	queue_free()
	return true


## Ajusta as cores e materiais do modelo para diferenciacao visual imediata.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _apply_visual_styling() -> void:
	if mesh_instance == null:
		return
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.roughness = 0.4
	mat.metallic = 0.6
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 2.0
	
	if pickup_type == PickupType.AMMO_CRATE:
		# Verde militar com emissao fluorescente
		mat.albedo_color = Color(0.18, 0.45, 0.22, 1.0)
		mat.emission = Color(0.2, 0.8, 0.3, 1.0)
	else:
		# Amarelo/Dourado de combustivel
		mat.albedo_color = Color(0.85, 0.65, 0.1, 1.0)
		mat.emission = Color(1.0, 0.7, 0.1, 1.0)
	
	mesh_instance.material_override = mat


## Localiza o WeaponManager na hierarquia da entidade.
##
## Args:
##     node (Node): No raiz da aeronave.
##
## Returns:
##     WeaponManager: Instancia encontrada ou null.
func _find_weapon_manager(node: Node) -> WeaponManager:
	if node is WeaponManager:
		return node as WeaponManager
	return node.get_node_or_null("WeaponManager") as WeaponManager


## Localiza o FuelComponent na hierarquia da entidade.
##
## Args:
##     node (Node): No raiz da aeronave.
##
## Returns:
##     FuelComponent: Instancia encontrada ou null.
func _find_fuel_component(node: Node) -> FuelComponent:
	if node is FuelComponent:
		return node as FuelComponent
	return node.get_node_or_null("FuelComponent") as FuelComponent


## Manipulador disparado ao detectar a entrada de corpo na area do suprimento.
##
## Args:
##     body (Node3D): Corpo que colidiu com a area.
##
## Returns:
##     void
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "PlayerHelicopter" or body is PlayerHelicopter:
		collect(body)
