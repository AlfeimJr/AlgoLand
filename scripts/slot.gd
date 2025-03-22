extends Node2D

@export var accepted_types: Array[String] = ["sword"]

func _ready() -> void:
	$Area2D.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	$Area2D.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	# Certifique-se de que a área está configurada corretamente
	$Area2D.monitoring = true
	$Area2D.monitorable = true

func accepts_item_type(item_type: String) -> bool:
	return accepted_types.has(item_type)

func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("get_item_type"):
		var itype = parent.get_item_type()
		if accepts_item_type(itype):
			parent.is_inside_dropable = true
			parent.slot_ref = self

func _on_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("get_item_type"):
		parent.is_inside_dropable = false
		parent.slot_ref = null
	print("Slot: item saiu")
