extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var loot_root: Node3D = $Loot
@onready var extraction_zone: Area3D = $ExtractionZone
@onready var hud_label: Label = $UI/HUD/MarginContainer/VBoxContainer/StatusLabel
@onready var decor_root: Node3D = $EnvironmentDecor

var loot_collected: int = 0
var extracted: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 24021989
	_build_environment_decor()
	for node in loot_root.get_children():
		node.add_to_group("loot_pickup")
	_update_hud("Collect loot and extract.")

func _physics_process(_delta: float) -> void:
	if extracted:
		return
	_collect_loot()
	_check_extraction()

func _collect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot_pickup"):
		if not is_instance_valid(loot):
			continue
		if loot.global_position.distance_to(player.global_position) < 1.9:
			loot.queue_free()
			loot_collected += 1
			_update_hud("Loot collected: %d" % loot_collected)

func _check_extraction() -> void:
	if not extraction_zone.overlaps_body(player):
		return
	if loot_collected > 0:
		extracted = true
		_update_hud("Extraction successful with %d loot." % loot_collected)
	else:
		_update_hud("Find loot before extraction.")

func _update_hud(message: String) -> void:
	hud_label.text = "%s\nLoot: %d" % [message, loot_collected]

func _build_environment_decor() -> void:
	_build_mountain_ring(70.0, 24)
	_scatter_pine_trees(65)
	_scatter_rocks(36)
	_scatter_snow_mounds(22)

func _build_mountain_ring(radius: float, count: int) -> void:
	var mountain_material := StandardMaterial3D.new()
	mountain_material.albedo_color = Color(0.53, 0.57, 0.62)
	mountain_material.roughness = 0.98

	for i in count:
		var angle := TAU * float(i) / float(count)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var mountain := MeshInstance3D.new()
		var mountain_mesh := CylinderMesh.new()
		var base_radius := _rng.randf_range(6.5, 11.0)
		var height := _rng.randf_range(10.0, 20.0)
		mountain_mesh.top_radius = 0.6
		mountain_mesh.bottom_radius = base_radius
		mountain_mesh.height = height
		mountain.mesh = mountain_mesh
		mountain.material_override = mountain_material
		mountain.position = direction * radius
		mountain.position.y = height * 0.5 - 0.5
		mountain.rotation.y = _rng.randf_range(0.0, TAU)
		decor_root.add_child(mountain)

func _scatter_pine_trees(count: int) -> void:
	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.23, 0.16, 0.11)
	trunk_material.roughness = 0.92

	var foliage_material := StandardMaterial3D.new()
	foliage_material.albedo_color = Color(0.14, 0.28, 0.2)
	foliage_material.roughness = 0.95

	var snow_cap_material := StandardMaterial3D.new()
	snow_cap_material.albedo_color = Color(0.96, 0.98, 1.0)
	snow_cap_material.roughness = 0.86

	for _i in count:
		var tree_root := Node3D.new()
		var tree_scale := _rng.randf_range(0.85, 1.35)
		tree_root.position = _sample_ring_position(16.0, 55.0)
		tree_root.rotation.y = _rng.randf_range(0.0, TAU)
		tree_root.scale = Vector3.ONE * tree_scale

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.2
		trunk_mesh.bottom_radius = 0.24
		trunk_mesh.height = 2.2
		trunk.mesh = trunk_mesh
		trunk.material_override = trunk_material
		trunk.position.y = 1.1
		tree_root.add_child(trunk)

		for layer in 3:
			var leaves := MeshInstance3D.new()
			var leaf_mesh := CylinderMesh.new()
			leaf_mesh.top_radius = 0.08
			leaf_mesh.bottom_radius = 1.25 - (layer * 0.25)
			leaf_mesh.height = 1.7
			leaves.mesh = leaf_mesh
			leaves.material_override = foliage_material
			leaves.position.y = 1.8 + layer * 0.7
			tree_root.add_child(leaves)

		var snow_cap := MeshInstance3D.new()
		var snow_mesh := SphereMesh.new()
		snow_mesh.radius = 0.36
		snow_mesh.height = 0.55
		snow_cap.mesh = snow_mesh
		snow_cap.material_override = snow_cap_material
		snow_cap.position.y = 4.0
		tree_root.add_child(snow_cap)

		decor_root.add_child(tree_root)

func _scatter_rocks(count: int) -> void:
	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.48, 0.52, 0.57)
	rock_material.roughness = 1.0

	for _i in count:
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = _rng.randf_range(0.35, 0.9)
		rock_mesh.height = _rng.randf_range(0.45, 1.2)
		rock.mesh = rock_mesh
		rock.material_override = rock_material
		rock.position = _sample_ring_position(8.0, 52.0)
		rock.position.y = rock_mesh.height * 0.22
		rock.scale = Vector3(
			_rng.randf_range(0.8, 1.5),
			_rng.randf_range(0.45, 0.9),
			_rng.randf_range(0.9, 1.6)
		)
		rock.rotation = Vector3(
			_rng.randf_range(0.0, 0.2),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(0.0, 0.2)
		)
		decor_root.add_child(rock)

func _scatter_snow_mounds(count: int) -> void:
	var mound_material := StandardMaterial3D.new()
	mound_material.albedo_color = Color(0.95, 0.98, 1.0)
	mound_material.roughness = 0.9

	for _i in count:
		var mound := MeshInstance3D.new()
		var mound_mesh := SphereMesh.new()
		mound_mesh.radius = _rng.randf_range(0.6, 1.3)
		mound_mesh.height = _rng.randf_range(0.4, 0.9)
		mound.mesh = mound_mesh
		mound.material_override = mound_material
		mound.position = _sample_ring_position(4.0, 50.0)
		mound.position.y = mound_mesh.height * 0.3
		mound.scale = Vector3(
			_rng.randf_range(1.0, 1.7),
			_rng.randf_range(0.35, 0.7),
			_rng.randf_range(1.0, 1.7)
		)
		decor_root.add_child(mound)

func _sample_ring_position(min_radius: float, max_radius: float) -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(min_radius, max_radius)
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
