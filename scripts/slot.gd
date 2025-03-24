extends Node2D

@export var accepted_types: Array[String] = ["sword_basic", "shield_basic", "spear_basic"]

# Variável para armazenar a referência do item que foi arrastado para o slot
var current_item: Node = null
signal item_changed(has_item: bool)
func _ready() -> void:
	$Area2D.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	$Area2D.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	$Area2D.monitoring = true
	$Area2D.monitorable = true

# Função que verifica se o tipo do item é aceito pelo slot
func accepts_item_type(item_type: String) -> bool:
	return accepted_types.has(item_type)

# Quando uma área (normalmente, o item arrastado) entra na área do slot...
func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	# O item arrastado deve implementar a função get_item_type()
	if parent.has_method("get_item_type"):
		var itype = parent.get_item_type()
		if accepts_item_type(itype):
			# Marca que o item pode ser dropado aqui
			parent.is_inside_dropable = true
			parent.slot_ref = self
			current_item = parent  # Armazena o item atual no slot
			emit_signal("item_changed", true)
			
# Quando a área sai, limpa a referência ao item
func _on_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("get_item_type"):
		parent.is_inside_dropable = false
		parent.slot_ref = null
		if current_item == parent:
			current_item = null
			emit_signal("item_changed", false)
	print("Slot: item saiu")
		
