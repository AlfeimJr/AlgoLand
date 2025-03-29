extends CanvasLayer

func _ready() -> void:
	$CharacterInfo.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_pressed("show_stats"):
		$CharacterInfo.visible = true
		update_menu()
	else:
		$CharacterInfo.visible = false

func update_menu() -> void:
	var player = get_tree().get_root().get_node("cenario/Player")
	if player == null:
		return

	# --- Atualizar Estatísticas do Player (em um GridContainer) ---
	for child in $CharacterInfo/PlayerStatus.get_children():
		child.queue_free()

	var stats_array = [
		"STR: " + str(player.stats.strength),
		"AGI: " + str(player.stats.agility),
		"VIT: " + str(player.stats.vitality),
		"INT: " + str(player.stats.intelligence),
		"LCK: " + str(player.stats.luck),
		"DEF: " + str(player.stats.defense),
		"DMG: " + str(player.stats.attack_damage)
	]

	var font_file: FontFile = load("res://UI/Planes_ValMore.ttf") as FontFile

	for stat_line in stats_array:
		var label = Label.new()
		label.text = stat_line
		
		label.add_theme_font_override("font", font_file)
		label.add_theme_font_size_override("font_size", 8)  # Tamanho definido aqui
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_constant_override("line_spacing", 3)
		
		label.add_theme_color_override("shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_size", 1)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		
		$CharacterInfo/PlayerStatus.add_child(label)

	# --- Atualizar Itens Comprados (em outro GridContainer) ---
	for child in $CharacterInfo/BackgroundItemsPurchased/ItemsPurchased.get_children():
		child.queue_free()

	if player.purchased_items.size() > 0:
		var item_scene = preload("res://cenas/item.tscn")
		for item_data in player.purchased_items:
			var item_instance = item_scene.instantiate()
			item_instance.set_item_data(item_data)
			$CharacterInfo/BackgroundItemsPurchased/ItemsPurchased.add_child(item_instance)
	else:
		var empty_label = Label.new()
		empty_label.text = "NO ITEMS PURCHASED"
		empty_label.add_theme_font_override("font", font_file)
		empty_label.add_theme_font_size_override("font_size", 8)  # Adicione aqui também
		empty_label.add_theme_color_override("font_color", Color.WHITE)
		$CharacterInfo/BackgroundItemsPurchased/ItemsPurchased.add_child(empty_label)
