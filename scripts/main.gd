extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var loot_root: Node3D = $Loot
@onready var extraction_zone: Area3D = $ExtractionZone
@onready var hud_label: Label = $UI/HUD/MarginContainer/VBoxContainer/StatusLabel

var loot_collected: int = 0
var extracted: bool = false

func _ready() -> void:
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
