## Mina naval flutuante liberada pelo chefe Apex Bastion.
##
## Flutua na superfície aquática e detona por proximidade caso o helicóptero
## voe em baixa altitude (Y <= 1.5m) num raio de 3.5m.
class_name FloatingNavalMine
extends Area3D

## Sinal emitido ao detonar.
signal mine_detonated()

@export var damage: float = 250.0
@export var trigger_radius: float = 3.5
@export var max_trigger_altitude: float = 1.5
@export var lifetime: float = 18.0

var elapsed: float = 0.0
var has_detonated: bool = false


## Inicializa colisões e conexões físicas.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	# Camada 6 = Enemy_Projectiles (32), mascara para Player_Air (2)
	collision_layer = 32
	collision_mask = 2
	body_entered.connect(_on_body_entered)


## Processa o monitoramento do jogador na água a cada quadro.
##
## Args:
##     delta (float): Tempo em segundos.
##
## Returns:
##     void
func _physics_process(delta: float) -> void:
	if has_detonated:
		return
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var players: Array[Node] = tree.get_nodes_in_group("player")
	if players.is_empty():
		return
	
	var player: Node3D = players[0] as Node3D
	if player == null or not is_instance_valid(player):
		return
	
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= trigger_radius and player.global_position.y <= max_trigger_altitude:
		detonate(player)


## Detona a mina e causa dano à entidade.
##
## Args:
##     target (Node): Alvo atingido.
##
## Returns:
##     void
func detonate(target: Node = null) -> void:
	if has_detonated:
		return
	has_detonated = true
	mine_detonated.emit()
	
	if target != null and target.has_node("HealthComponent"):
		var hc: HealthComponent = target.get_node("HealthComponent") as HealthComponent
		if hc != null:
			hc.take_damage(damage, self)
	
	queue_free()


## Callback de colisão direta de corpo.
##
## Args:
##     body (Node3D): Corpo colisor.
##
## Returns:
##     void
func _on_body_entered(body: Node3D) -> void:
	if body != null and body.is_in_group("player"):
		detonate(body)
