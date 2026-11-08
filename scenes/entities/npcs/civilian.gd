## Entidade de sobrevivente civil no solo aguardando evacuacao.
##
## Possui integridade fisica reduzida gerenciada por HealthComponent, sendo vulneravel
## a explosoes em area e fogo cruzado. Ao ser eliminado, notifica o EventBus.
class_name Civilian
extends CharacterBody3D

## Gravidade padrao aplicada para repouso no solo.
const GRAVITY: float = 9.8

## Referencia ao componente de integridade fisica.
@onready var health_component: HealthComponent = $HealthComponent

## Referências aos membros para animação procedural de socorro.
@onready var arm_left: Node3D = get_node_or_null("ModelContainer/ArmLeft") as Node3D
@onready var arm_right: Node3D = get_node_or_null("ModelContainer/ArmRight") as Node3D

## Estados de ciclo de vida do sobrevivente em campo.
enum CivilianState {
	WAITING,
	RESCUED,
	KILLED
}

## Estado operacional atual da entidade.
var state: CivilianState = CivilianState.WAITING

## Propriedade de conveniencia indicando se a entidade foi eliminada por dano.
var is_dead: bool:
	get:
		return state == CivilianState.KILLED

## Propriedade de conveniencia indicando se o civil foi resgatado com sucesso a bordo.
var is_rescued: bool:
	get:
		return state == CivilianState.RESCUED


## Inicializa a entidade conectando sinais de vida e registrando no grupo de civis.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	add_to_group("civilians")
	
	if health_component != null:
		health_component.entity_destroyed.connect(_on_entity_destroyed)


## Aplica gravidade para assentamento estavel sobre o terreno da ilha.
##
## Args:
##     delta (float): Intervalo de tempo do quadro de fisica em segundos.
##
## Returns:
##     void
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	
	move_and_slide()
	
	if state == CivilianState.WAITING:
		_process_waving_animation(delta)


## Animação procedural de socorro com braços erguidos acenando para a aeronave.
##
## Args:
##     delta (float): Intervalo de tempo físico em segundos.
##
## Returns:
##     void
func _process_waving_animation(_delta: float) -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.006
	if arm_left != null:
		arm_left.rotation.z = deg_to_rad(140.0) + sin(t) * deg_to_rad(25.0)
	if arm_right != null:
		arm_right.rotation.z = -deg_to_rad(140.0) - sin(t + PI * 0.5) * deg_to_rad(25.0)


## Aplica dano direto ou em area a entidade repassando ao HealthComponent.
##
## Args:
##     amount (float): Quantidade de dano a aplicar.
##     source (Node3D): Instancia causadora do dano (opcional).
##
## Returns:
##     void
func take_damage(amount: float, source: Node3D = null) -> void:
	if state != CivilianState.WAITING:
		return
	if health_component != null:
		health_component.take_damage(amount, source)


## Processa o resgate bem-sucedido do civil a bordo da aeronave.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func rescue() -> void:
	if state != CivilianState.WAITING:
		return
	state = CivilianState.RESCUED
	queue_free()


## Manipulador disparado quando o HealthComponent atinge zero de saude.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _on_entity_destroyed() -> void:
	if state != CivilianState.WAITING:
		return
	state = CivilianState.KILLED
	
	if GameState != null:
		GameState.register_killed_civilian(1)
	elif EventBus != null:
		EventBus.civilian_killed.emit(1)
	
	queue_free()
