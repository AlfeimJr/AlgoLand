extends Node2D

@export var tipos_aceitos: Array[String] = []  # Se vazio, aceita todos os tipos
signal item_alterado(tem_item: bool)

# Variável para armazenar a referência do item dropado neste slot
var item_atual: Node = null

func _ready() -> void:
	# Configurar as camadas para o inventário (exemplo: layer 15, mask 15)
	$Area2D.collision_layer = 15
	$Area2D.collision_mask = 15
	
	$Area2D.connect("area_entered", Callable(self, "_ao_area_2d_area_entrou"))
	$Area2D.connect("area_exited", Callable(self, "_ao_area_2d_area_saiu"))
	$Area2D.connect("mouse_entered", Callable(self, "_ao_area_2d_mouse_entrou"))
	$Area2D.connect("mouse_exited", Callable(self, "_ao_area_2d_mouse_saiu"))
	
	$Area2D.monitoring = true
	$Area2D.monitorable = true

# Função que verifica se o tipo do item é aceito pelo slot.
# Se tipos_aceitos estiver vazio, aceita qualquer item.
func aceita_tipo_item(tipo_item: String) -> bool:
	if tipos_aceitos.size() == 0:
		return true
	return tipos_aceitos.has(tipo_item)

# Quando um item (área) entra na área do slot...
func _ao_area_2d_area_entrou(area: Area2D) -> void:
	var pai = area.get_parent()
	# O item dropado deve implementar a função obter_tipo_item()
	if pai.has_method("obter_tipo_item"):
		var tipo = pai.obter_tipo_item()
		if aceita_tipo_item(tipo):
			# Marca que o item pode ser dropado aqui
			pai.esta_dentro_area_soltar = true
			pai.ref_slot = self
			item_atual = pai  # Armazena o item atual no slot
			emit_signal("item_alterado", true)

# Quando o item sai da área do slot, limpa a referência
func _ao_area_2d_area_saiu(area: Area2D) -> void:
	var pai = area.get_parent()
	if pai.has_method("obter_tipo_item"):
		pai.esta_dentro_area_soltar = false
		pai.ref_slot = null
		if item_atual == pai:
			item_atual = null
			emit_signal("item_alterado", false)
	print("Slot: item saiu")

# Efeitos visuais ao passar o mouse sobre o slot
func _ao_area_2d_mouse_entrou() -> void:
	# Exemplo: destaque com modulação ou mudança de escala
	modulate = Color(1, 1, 1, 1)  # Ajuste conforme sua arte

func _ao_area_2d_mouse_saiu() -> void:
	modulate = Color(1, 1, 1, 1)
