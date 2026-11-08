## Estrutura blindada de abrigo destrutivel contendo especialistas refens.
##
## Protege os sobreviventes com 300.0 HP de integridade estrutural. Ao sofrer colapso,
## notifica o EventBus e libera 4 civis em dispersao radial ao redor da fundacao.
class_name RescueShelter
extends StaticBody3D

## Recurso de configuracao dos atributos do abrigo.
@export var shelter_data: ShelterData

## Cena instanciada para cada sobrevivente liberado no colapso.
@export var civilian_scene: PackedScene

## Referencia ao componente de integridade estrutural.
@onready var health_component: HealthComponent = $HealthComponent

## Flag para prevenir liberacao duplicada durante o frame de exclusao.
var is_collapsed: bool = false


## Configura o abrigo adicionando ao grupo de estruturas e sincronizando saude.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	add_to_group("structures")
	
	if shelter_data == null:
		shelter_data = preload("res://scripts/data/rescue_shelter.tres")
	
	if civilian_scene == null:
		civilian_scene = preload("res://scenes/entities/npcs/civilian.tscn")
	
	if health_component != null and shelter_data != null:
		health_component.max_health = shelter_data.max_health
		health_component.current_health = shelter_data.max_health
		health_component.entity_destroyed.connect(_on_entity_destroyed)


## Aplica dano a estrutura delegando a operacao ao HealthComponent.
##
## Args:
##     amount (float): Intensidade do dano a aplicar.
##     source (Node3D): Instancia originadora do ataque (opcional).
##
## Returns:
##     void
func take_damage(amount: float, source: Node3D = null) -> void:
	if is_collapsed:
		return
	if health_component != null:
		health_component.take_damage(amount, source)


## Processa a destruicao do edificio, emissao de sinais e geracao dos sobreviventes.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_entity_destroyed() -> void:
	if is_collapsed:
		return
	is_collapsed = true
	
	var survivor_count: int = 4
	var scatter_radius: float = 2.5
	
	if shelter_data != null:
		survivor_count = shelter_data.survivor_count
		scatter_radius = shelter_data.spawn_scatter_radius
	
	if EventBus != null:
		EventBus.shelter_destroyed.emit(global_position, survivor_count)
	
	_spawn_survivors(survivor_count, scatter_radius)
	queue_free()


## Gera as instancias dos civis distribuindo-as radialmente ao redor do abrigo.
##
## Args:
##     count (int): Numero de sobreviventes a instanciar.
##     radius (float): Distancia radial da fundacao em metros.
##
## Returns:
##     void
func _spawn_survivors(count: int, radius: float) -> void:
	if civilian_scene == null or count <= 0:
		return
	
	var parent_container: Node = get_parent()
	if parent_container == null:
		parent_container = self
	
	for i in range(count):
		var survivor_node: Node = civilian_scene.instantiate()
		var civilian: Node3D = survivor_node as Node3D
		if civilian == null:
			continue
		
		var angle: float = float(i) * (TAU / float(count))
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * radius
		
		if parent_container != self:
			parent_container.add_child(civilian)
			civilian.global_position = global_position + offset
		else:
			# Fallback se nao possuir pai anexado na arvore
			add_child(civilian)
			civilian.position = offset
