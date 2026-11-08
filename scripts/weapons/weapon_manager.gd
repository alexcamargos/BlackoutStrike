## Gerenciador de arsenal, controle de cadencia, municoes e slots balisticos.
##
## Administra a troca entre Canhao Vulcan, Foguetes Hydra e Mísseis Hellfire,
## validando a contagem de municao e aplicando os modificadores de dano e dispersao.
class_name WeaponManager
extends Node

## Emitido quando o jogador alterna o armamento ativo.
signal weapon_switched(slot_index: int, weapon_data: WeaponData)

## Emitido quando o estoque de municao de qualquer slot sofre alteracao.
signal ammo_updated(slot_index: int, current: int, max_ammo: int)

## Emitido no instante em que um projetil e disparado com sucesso no mundo.
signal shot_fired(slot_index: int, projectile_instance: Projectile)

@export_group("Slots de Armas")
## Catalogo de armamentos equipados na aeronave.
@export var weapon_slots: Array[WeaponData] = []

## Indice do slot de arma selecionado atualmente (0: Vulcan, 1: Hydra, 2: Hellfire).
var current_slot_index: int = 0

## Estoque de municao individualizado por slot.
var ammo_counts: Array[int] = []

## Cronometro interno de resfriamento entre disparos (cadencia).
var cooldown_timer: float = 0.0

@export_group("Modificadores Globais de Dano e Balistica")
## Multiplicador de dano aplicado aos disparos (ex: concedido por boons).
var damage_multiplier: float = 1.0

## Bonus percentual de dano contra estruturas e edificacoes.
var structure_damage_bonus: float = 0.0

## Habilita a transpassagem de um alvo pelo disparo inicial de canhao.
var pierce_first_target: bool = false


## Inicializa o inventario de municao e notifica a interface sobre os dados iniciais.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	if weapon_slots.is_empty():
		_load_default_slots()
	
	_initialize_ammo()
	
	if not weapon_slots.is_empty():
		var active_weapon: WeaponData = weapon_slots[current_slot_index]
		weapon_switched.emit(current_slot_index, active_weapon)
		if EventBus != null:
			EventBus.weapon_selected.emit(current_slot_index, active_weapon.display_name)
			for i in range(weapon_slots.size()):
				EventBus.weapon_ammo_changed.emit(i, ammo_counts[i], weapon_slots[i].max_ammo)


## Reduz continuamente o tempo de espera entre rajadas conforme a cadencia.
##
## Args:
##     delta (float): Intervalo de tempo fisico em segundos.
##
## Returns:
##     void
func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer = maxf(0.0, cooldown_timer - delta)


## Alterna o armamento ativo para o indice especificado.
##
## Args:
##     slot_index (int): Indice do slot desejado (0 a N-1).
##
## Returns:
##     void
func select_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= weapon_slots.size():
		return
	
	current_slot_index = slot_index
	var weapon: WeaponData = weapon_slots[current_slot_index]
	weapon_switched.emit(current_slot_index, weapon)
	
	if EventBus != null:
		EventBus.weapon_selected.emit(current_slot_index, weapon.display_name)


## Avanca ciclicamente para o proximo armamento disponivel.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func cycle_next_slot() -> void:
	if weapon_slots.is_empty():
		return
	var next_index: int = (current_slot_index + 1) % weapon_slots.size()
	select_slot(next_index)


## Tenta disparar a arma ativa a partir de uma coordenada espacial e orientacao.
##
## Args:
##     muzzle_transform (Transform3D): Origem e orientacao espacial do cano da arma.
##     target_node (Node3D): Alvo teleguiado opcional (para mísseis).
##
## Returns:
##     bool: True se o tiro foi deflagrado com sucesso, False se bloqueado por cadencia ou falta de municao.
func try_fire(muzzle_transform: Transform3D, target_node: Node3D = null) -> bool:
	if weapon_slots.is_empty() or current_slot_index >= weapon_slots.size():
		return false
	
	if cooldown_timer > 0.0:
		return false
	
	if ammo_counts.size() <= current_slot_index or ammo_counts[current_slot_index] <= 0:
		return false
	
	var weapon: WeaponData = weapon_slots[current_slot_index]
	
	# Consumo de municao
	ammo_counts[current_slot_index] -= 1
	cooldown_timer = 1.0 / maxf(0.1, weapon.fire_rate)
	
	ammo_updated.emit(current_slot_index, ammo_counts[current_slot_index], weapon.max_ammo)
	if EventBus != null:
		EventBus.weapon_ammo_changed.emit(current_slot_index, ammo_counts[current_slot_index], weapon.max_ammo)
	
	# Instanciacao do projetil fisico
	var spawned_proj: Projectile = null
	if weapon.projectile_scene != null:
		spawned_proj = weapon.projectile_scene.instantiate() as Projectile
		if spawned_proj != null:
			_configure_projectile(spawned_proj, weapon, muzzle_transform, target_node)
			
			var tree: SceneTree = get_tree()
			if tree != null and tree.current_scene != null:
				tree.current_scene.add_child(spawned_proj)
				spawned_proj.global_transform = muzzle_transform
				
				# Aplica dispersao angular se configurada
				if weapon.spread_angle_deg > 0.0:
					_apply_spread(spawned_proj, weapon.spread_angle_deg)
	
	shot_fired.emit(current_slot_index, spawned_proj)
	return true


## Repoe percentualmente o estoque de municao de todos os slots de armas.
##
## Args:
##     fraction (float): Fracao decimal da capacidade maxima (ex: 0.25 para +25%).
##
## Returns:
##     void
func replenish_ammo_fraction(fraction: float) -> void:
	if fraction <= 0.0:
		return
	
	for i in range(weapon_slots.size()):
		var max_cap: int = weapon_slots[i].max_ammo
		var add_amount: int = int(round(float(max_cap) * fraction))
		ammo_counts[i] = mini(max_cap, ammo_counts[i] + add_amount)
		ammo_updated.emit(i, ammo_counts[i], max_cap)
		if EventBus != null:
			EventBus.weapon_ammo_changed.emit(i, ammo_counts[i], max_cap)


## Retorna a quantidade de municao disponivel no slot ativo.
##
## Args:
##     Nenhum.
##
## Returns:
##     int: Municao restante.
func get_current_ammo() -> int:
	if current_slot_index < ammo_counts.size():
		return ammo_counts[current_slot_index]
	return 0


## Retorna o recurso de dados da arma ativa.
##
## Args:
##     Nenhum.
##
## Returns:
##     WeaponData: Recurso do slot corrente.
func get_current_weapon_data() -> WeaponData:
	if current_slot_index < weapon_slots.size():
		return weapon_slots[current_slot_index]
	return null


## Aplica um multiplicador na capacidade maxima de municao de todos os slots equipados.
##
## Usado pela meta-progressao de Hangar (Logistica de Calibre).
##
## Args:
##     multiplier (float): Fator multiplicativo da capacidade (ex: 1.2 para +20%).
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func apply_ammo_capacity_multiplier(multiplier: float) -> void:
	if multiplier <= 0.0 or not is_finite(multiplier):
		return
	
	for i in range(weapon_slots.size()):
		var slot: WeaponData = weapon_slots[i]
		if slot != null:
			var duplicated_slot: WeaponData = slot.duplicate()
			duplicated_slot.max_ammo = int(round(float(slot.max_ammo) * multiplier))
			weapon_slots[i] = duplicated_slot
			if i < ammo_counts.size():
				ammo_counts[i] = duplicated_slot.max_ammo
			ammo_updated.emit(i, ammo_counts[i], duplicated_slot.max_ammo)
			if EventBus != null:
				EventBus.weapon_ammo_changed.emit(i, ammo_counts[i], duplicated_slot.max_ammo)


## Inicializa os estoques de municao com base nas capacidades maximas de cada slot.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _initialize_ammo() -> void:
	ammo_counts.clear()
	for slot in weapon_slots:
		if slot != null:
			ammo_counts.append(slot.max_ammo)
		else:
			ammo_counts.append(0)


## Configura as propriedades de balistica e teleguiamento do projetil recem-instanciado.
##
## Args:
##     proj (Projectile): Instancia do projetil.
##     weapon (WeaponData): Dados da arma de origem.
##     muzzle_xform (Transform3D): Ponto e orientacao de disparo.
##     target (Node3D): Alvo teleguiado opcional.
##
## Returns:
##     void
func _configure_projectile(proj: Projectile, weapon: WeaponData, muzzle_xform: Transform3D, target: Node3D) -> void:
	proj.damage = weapon.base_damage * damage_multiplier
	proj.speed = weapon.projectile_speed
	proj.explosion_radius = weapon.explosion_radius
	proj.structure_damage_bonus = structure_damage_bonus
	proj.pierce_remaining = 1 if pierce_first_target else 0
	proj.is_homing = weapon.is_homing
	proj.homing_turn_speed = weapon.homing_turn_speed
	proj.homing_target = target
	
	# Associa o no disparador para prevenir colisao imediata com o atirador
	var shooter: Node = get_parent()
	if shooter is Node3D:
		proj.source = shooter as Node3D


## Aplica dispersao conica estocastica a trajetoria do projetil.
##
## Args:
##     proj (Projectile): Projetil cujo vetor direcional sera perturbado.
##     spread_deg (float): Angulo maximo de desvio em graus.
##
## Returns:
##     void
func _apply_spread(proj: Projectile, spread_deg: float) -> void:
	var spread_rad: float = deg_to_rad(spread_deg)
	var yaw_offset: float = randf_range(-spread_rad, spread_rad)
	var pitch_offset: float = randf_range(-spread_rad, spread_rad)
	proj.rotate_object_local(Vector3.UP, yaw_offset)
	proj.rotate_object_local(Vector3.RIGHT, pitch_offset)


## Carrega a configuracao padrao de 3 slots caso o array de armas esteja vazio.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _load_default_slots() -> void:
	var v_data: WeaponData = WeaponData.new()
	v_data.id = "vulcan_20mm"
	v_data.display_name = "Canhao Rotativo Vulcan"
	v_data.max_ammo = 1200
	v_data.fire_rate = 12.0
	v_data.base_damage = 14.0
	v_data.projectile_speed = 120.0
	v_data.spread_angle_deg = 2.0
	v_data.projectile_scene = load("res://scenes/weapons/projectile_vulcan.tscn")
	
	var h_data: WeaponData = WeaponData.new()
	h_data.id = "hydra_70"
	h_data.display_name = "Foguetes Hydra 70"
	h_data.max_ammo = 32
	h_data.fire_rate = 2.0
	h_data.base_damage = 160.0
	h_data.projectile_speed = 65.0
	h_data.explosion_radius = 3.0
	h_data.projectile_scene = load("res://scenes/weapons/projectile_hydra.tscn")
	
	var m_data: WeaponData = WeaponData.new()
	m_data.id = "hellfire_agm"
	m_data.display_name = "Missil Hellfire"
	m_data.max_ammo = 6
	m_data.fire_rate = 1.0
	m_data.base_damage = 650.0
	m_data.projectile_speed = 50.0
	m_data.explosion_radius = 2.5
	m_data.is_homing = true
	m_data.homing_cone_deg = 40.0
	m_data.homing_turn_speed = 6.0
	m_data.projectile_scene = load("res://scenes/weapons/projectile_hellfire.tscn")
	
	weapon_slots = [v_data, h_data, m_data]
