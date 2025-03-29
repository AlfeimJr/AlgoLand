extends Node2D

@export var accepted_types: Array[String] = []  # Se vazio, aceita todos os tipos
signal item_changed(has_item: bool)

# Variável para armazenar a referência do item dropado neste slot
var current_item: Node = null

func _ready() -> void:
	# Configurar as camadas para o inventário (exemplo: layer 15, mask 15)
	$Area2D.collision_layer = 15
	$Area2D.collision_mask = 15
	
	$Area2D.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	$Area2D.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	$Area2D.connect("mouse_entered", Callable(self, "_on_area_2d_mouse_entered"))
	$Area2D.connect("mouse_exited", Callable(self, "_on_area_2d_mouse_exited"))
	
	$Area2D.monitoring = true
	$Area2D.monitorable = true

# Função que verifica se o tipo do item é aceito pelo slot.
# Se accepted_types estiver vazio, aceita qualquer item.
func accepts_item_type(item_type: String) -> bool:
	if accepted_types.size() == 0:
		return true
	return accepted_types.has(item_type)

# Quando um item (área) entra na área do slot...
func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	# O item dropado deve implementar a função get_item_type()
	if parent.has_method("get_item_type"):
		var itype = parent.get_item_type()
		if accepts_item_type(itype):
			# Marca que o item pode ser dropado aqui
			parent.is_inside_dropable = true
			parent.slot_ref = self
			current_item = parent  # Armazena o item atual no slot
			emit_signal("item_changed", true)

# Quando o item sai da área do slot, limpa a referência
func _on_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("get_item_type"):
		parent.is_inside_dropable = false
		parent.slot_ref = null
		if current_item == parent:
			current_item = null
			emit_signal("item_changed", false)
	print("Slot: item saiu")

# Efeitos visuais ao passar o mouse sobre o slot
func _on_area_2d_mouse_entered() -> void:
	# Exemplo: destaque com modulação ou mudança de escala
	modulate = Color(1, 1, 1, 1)  # Ajuste conforme sua arte

func _on_area_2d_mouse_exited() -> void:
	modulate = Color(1, 1, 1, 1)
