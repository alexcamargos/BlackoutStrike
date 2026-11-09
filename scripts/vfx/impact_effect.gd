## Efeito visual transiente de impacto de projetil com discriminacao por superficie e desalocacao automatica.
class_name ImpactEffect
extends Node3D

## Tipo de superficie receptora do impacto balistico.
enum SurfaceType {
	METAL,
	DIRT,
	WATER
}

## Duracao de exibicao do efeito antes de liberar memoria (segundos).
@export var duration: float = 0.45

## Referencias aos subsistemas de particulas e iluminacao.
@onready var metal_sparks: GPUParticles3D = get_node_or_null("MetalSparksParticles") as GPUParticles3D
@onready var dust_particles: GPUParticles3D = get_node_or_null("DustParticles") as GPUParticles3D
@onready var flash_light: OmniLight3D = get_node_or_null("FlashLight") as OmniLight3D

var timer: float = 0.0
var initial_light_energy: float = 4.0
var active_surface: SurfaceType = SurfaceType.METAL
var _has_explicit_surface: bool = false


## Inicializa o efeito visual ativando o sistema de particulas adequado.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func _ready() -> void:
	if flash_light != null:
		initial_light_energy = flash_light.light_energy
	if _has_explicit_surface:
		apply_surface(active_surface)
	else:
		apply_surface(active_surface)


## Configura a superficie do impacto com base no alvo atingido e na cota espacial.
##
## Args:
##     target (Node): No atingido pelo projetil.
##     hit_pos (Vector3): Coordenadas globais do ponto de colisao.
##
## Returns:
##     void
func setup_for_target(target: Node, hit_pos: Vector3) -> void:
	if hit_pos.y <= 0.3:
		setup_surface(SurfaceType.WATER)
		return
	
	if target != null:
		if target.is_in_group("metal") or target.is_in_group("enemies") or target.is_in_group("vehicles") or target.is_in_group("boss"):
			setup_surface(SurfaceType.METAL)
			return
		if target.is_in_group("terrain") or target.is_in_group("structures"):
			setup_surface(SurfaceType.DIRT)
			return
	
	setup_surface(SurfaceType.DIRT)


## Define diretamente a superficie e chaveia os emissores de particulas GPU.
##
## Args:
##     surface (SurfaceType): Tipo de superficie receptora.
##
## Returns:
##     void
func setup_surface(surface: SurfaceType) -> void:
	active_surface = surface
	_has_explicit_surface = true
	if is_node_ready():
		apply_surface(surface)


## Ativa e reinicia os sistemas de particulas especificos para a superficie ativa.
##
## Args:
##     surface (SurfaceType): Tipo de superficie a aplicar.
##
## Returns:
##     void
func apply_surface(surface: SurfaceType) -> void:
	match surface:
		SurfaceType.METAL:
			if metal_sparks != null:
				metal_sparks.emitting = true
				metal_sparks.restart()
			if dust_particles != null:
				dust_particles.emitting = false
		SurfaceType.DIRT:
			if dust_particles != null:
				dust_particles.emitting = true
				dust_particles.restart()
			if metal_sparks != null:
				metal_sparks.emitting = false
		SurfaceType.WATER:
			if dust_particles != null:
				dust_particles.emitting = false
			if metal_sparks != null:
				metal_sparks.emitting = false


## Controla o decaimento luminoso do clarao e a remocao automatica do efeito visual.
##
## Args:
##     delta (float): Intervalo de tempo do quadro em segundos.
##
## Returns:
##     void
func _process(delta: float) -> void:
	timer += delta
	if flash_light != null and duration > 0.0:
		flash_light.light_energy = lerpf(initial_light_energy, 0.0, clampf(timer / duration, 0.0, 1.0))
	
	if timer >= duration:
		queue_free()
