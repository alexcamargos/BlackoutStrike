@tool
## Complexo portuario modular montado por kitbashing no Godot com overrides PBR triplanares.
class_name PortComplexA
extends Node3D

@export var red_container_material: Material = preload("res://assets/materials/mat_container_red_weathered.tres")
@export var steel_container_material: Material = preload("res://assets/materials/mat_container_steel_weathered.tres")
@export var rust_industrial_material: Material = preload("res://assets/materials/mat_industrial_corrugated_rust.tres")


## Aplica os materiais PBR triplanares nos conteineres e modulos do porto.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
##
## Raises:
##     Nenhuma excecao levantada.
func _ready() -> void:
	_apply_override_to_node("ContainerStack_Red_1", red_container_material)
	_apply_override_to_node("ContainerStack_Red_2", red_container_material)
	_apply_override_to_node("ContainerStack_Steel_1", steel_container_material)
	_apply_override_to_node("ContainerStack_Rust_1", rust_industrial_material)


func _apply_override_to_node(node_name: String, mat: Material) -> void:
	if mat == null:
		return
	var target: Node = get_node_or_null(node_name)
	if target == null:
		return
	_set_material_recursive(target, mat)


func _set_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_set_material_recursive(child, mat)
