extends SceneTree

const MANIFEST_PATH: String = "res://assets/reference/visual_contract/manifest.json"
const SCENES_PATH: String = "res://scenes"
const FORBIDDEN_MESH_CLASSES: Array[String] = [
	"BoxMesh", "CapsuleMesh", "CylinderMesh", "SphereMesh", "PlaneMesh", "QuadMesh"
]

var failures: PackedStringArray = PackedStringArray()
var manifest_is_approved: bool = false

func _init() -> void:
	validate_manifest()
	if manifest_is_approved:
		validate_production_scenes(SCENES_PATH)
	for failure: String in failures:
		push_error(failure)
	quit(1 if not failures.is_empty() else 0)

func validate_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		failures.append("Visual Contract: manifest ausente em %s." % MANIFEST_PATH)
		return
	var manifest_file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Visual Contract: manifest JSON inválido.")
		return
	var manifest: Dictionary = parsed as Dictionary
	if manifest.get("contract_status", "") != "APPROVED":
		failures.append("Visual Contract: referências não aprovadas; status atual: %s." % manifest.get("contract_status", "ausente"))
		return
	manifest_is_approved = true
	var baselines: Array = manifest.get("baselines", []) as Array
	for baseline_variant: Variant in baselines:
		if not (baseline_variant is Dictionary):
			failures.append("Visual Contract: baseline inválido no manifesto.")
			continue
		var baseline: Dictionary = baseline_variant as Dictionary
		var filename: String = str(baseline.get("file", ""))
		if filename.is_empty() or baseline.get("sha256", null) == null:
			failures.append("Visual Contract: baseline sem arquivo ou SHA-256: %s." % baseline.get("id", "desconhecido"))
			continue
		if not FileAccess.file_exists("res://assets/reference/visual_contract/%s" % filename):
			failures.append("Visual Contract: baseline ausente: %s." % filename)

func validate_production_scenes(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		failures.append("Visual Contract: diretório de cenas não encontrado: %s." % directory_path)
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = directory_path.path_join(entry)
			if directory.current_is_dir():
				validate_production_scenes(full_path)
			elif entry.ends_with(".tscn"):
				validate_scene_meshes(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func validate_scene_meshes(scene_path: String) -> void:
	var scene_file: FileAccess = FileAccess.open(scene_path, FileAccess.READ)
	if scene_file == null:
		failures.append("Visual Contract: cena não abriu: %s." % scene_path)
		return
	var scene_text: String = scene_file.get_as_text()
	for mesh_class: String in FORBIDDEN_MESH_CLASSES:
		if scene_text.contains("type=\"%s\"" % mesh_class):
			failures.append("Visual Contract: primitive mesh visível (%s) em %s." % [mesh_class, scene_path])
