extends Node2D

signal menu_closed
@export var detection_distance: float = 200.0

@onready var main_menu: Control = $Buttons
@onready var weapons_list: Control = $Weapons
@onready var build_list: Control = $ItemsContainer
@onready var items_container = $ItemsContainer
@onready var items_spec = $ItemSpec
@onready var back_button = $BackButton
@onready var coins_container = $Coins
@onready var start_wave_button: Button = $Buttons/StartWave
@onready var update_button: Button = $Buttons/Update
@onready var leave_button: Button = $Buttons/Leave
@onready var weapons_option_button: Button = $Buttons/weaponsOption
@onready var build_button: Button = $Buttons/Build
@onready var player = get_tree().get_root().get_node("cenario/Player")
@onready var alert_label: Label = $Update/Alert
@onready var upgrade_button: Button = $Update/UptadeClick
var item_scene = preload("res://cenas/item.tscn")
var wave_thresholds = {
	1: 4,
	2: 9,
	3: 20,
	4: 35
}

# Função genérica para extrair o tipo de arma da chave atual
func get_generic_weapon_type(current_weapon_id: String) -> String:
	if current_weapon_id.find("sword_basic") != -1:
		return "sword_basic"
	elif current_weapon_id.find("shield_basic") != -1:
		return "shield_basic"
	elif current_weapon_id.find("spear_basic") != -1:
		return "spear_basic"
	else:
		return ""

func _ready() -> void:
	
	if player and not player.is_connected("equipment_changed", Callable(self, "_on_player_equipment_changed")):
		player.connect("equipment_changed", Callable(self, "_on_player_equipment_changed"))
	var inventory = get_tree().get_root().get_node("cenario/Player/Invetario")
	if inventory:
		inventory.connect("item_selected", Callable(self, "_on_inventory_item_selected"))

	update_coins_display()

	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if wave_manager and wave_manager.is_wave_running:
		hide()
		return

	# Conexões de botões
	if start_wave_button and not start_wave_button.is_connected("pressed", Callable(self, "_on_start_wave_pressed")):
		start_wave_button.disabled = true
		start_wave_button.connect("pressed", Callable(self, "_on_start_wave_pressed"))

	if update_button and not update_button.is_connected("pressed", Callable(self, "_on_update_pressed")):
		update_button.connect("pressed", Callable(self, "_on_update_pressed"))

	if weapons_option_button and not weapons_option_button.is_connected("pressed", Callable(self, "_on_weapons_pressed")):
		weapons_option_button.connect("pressed", Callable(self, "_on_weapons_pressed"))

	if has_node("Container/Weapons/Sword"):
		var sword_button = $Container/Weapons/Sword
		if sword_button and not sword_button.is_connected("pressed", Callable(self, "_on_sword_pressed")):
			sword_button.connect("pressed", Callable(self, "_on_sword_pressed"))

	if has_node("Container/Weapons/Spear"):
		var spear_button = $Container/Weapons/Spear
		if spear_button:
			if spear_button is Button:
				if not spear_button.is_connected("pressed", Callable(self, "_on_spear_pressed")):
					spear_button.connect("pressed", Callable(self, "_on_spear_pressed"))
			else:
				if not spear_button.is_connected("gui_input", Callable(self, "_on_spear_gui_input")):
					spear_button.connect("gui_input", Callable(self, "_on_spear_gui_input"))

	# >>> ADICIONE ESTA PARTE PARA O ESCUDO <<<
	if has_node("Container/Weapons/Shield"):
		var shield_button = $Container/Weapons/Shield
		if shield_button and not shield_button.is_connected("pressed", Callable(self, "_on_shield_pressed")):
			shield_button.connect("pressed", Callable(self, "_on_shield_pressed"))

	if build_button and not build_button.is_connected("pressed", Callable(self, "_on_build_pressed")):
		build_button.connect("pressed", Callable(self, "_on_build_pressed"))

	if back_button and not back_button.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))

	if leave_button and not leave_button.is_connected("pressed", Callable(self, "_on_leave_pressed")):
		leave_button.connect("pressed", Callable(self, "_on_leave_pressed"))

	# Verifica se o player está usando espada ou lança
	if player:
		if player.using_sword:
			start_wave_button.disabled = false
			$Weapons/Arm/sword/Text.text = "UNEQUIP"
		else:
			$Weapons/Arm/sword/Text.text = "EQUIP"

		if player.using_spear:
			$Weapons/Spear/spear/Text.text = "UNEQUIP"
		else:
			$Weapons/Spear/spear/Text.text = "EQUIP"

		# (Opcional) Se quiser inicializar o texto do escudo:
		if player.using_shield:
			$Weapons/Shield/Shield/Text.text = "UNEQUIP"
		else:
			$Weapons/Shield/Shield/Text.text = "EQUIP"

		player.block_attacks(true)

func _on_inventory_item_selected(item_type: String, texture: Texture2D) -> void:
	print(texture)
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var player = get_tree().get_current_scene().get_node("Player")
	var current_level = 0
	var next_level = 0
	if item_type == "sword_basic":
		current_level = player.sword_level
		next_level = current_level 
	elif item_type == "shield_basic":
		current_level = player.shield_level
		next_level = current_level

	var next_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, next_level)
	if next_data.size() > 0:
		var needed_wave = next_data.get("wave_required", 9999)
		alert_label.text = "OPENS BY WINNING WAVE " + str(needed_wave)
	else:
		alert_label.text = "MAX LEVEL REACHED"

func _process(delta: float) -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		# Se quiser permitir iniciar a wave se tiver espada, lança ou escudo, mude para:
		start_wave_button.disabled = not (player.using_sword or player.using_spear or player.using_shield)
		update_button.disabled = not (player.using_sword or player.using_spear)
		# Se NÃO quiser permitir wave só com escudo, use a linha anterior do original:
		# start_wave_button.disabled = not (player.using_sword or player.using_spear)

	if Input.is_action_just_pressed("close_menu"):
		on_close_button_pressed()
func _on_button_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return
	player.equip_sword()
	if player.using_sword:
		$Weapons/Arm/sword/Text.text = "UNEQUIP"
	else:
		$Weapons/Arm/sword/Text.text = "EQUIP"
	if start_wave_button:
		start_wave_button.disabled = not player.using_sword

func _on_start_wave_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	print("Start wave pressed, using_sword:", player.using_sword)
	if player and not (player.using_sword or player.using_spear or player.using_shield):
		return
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if wave_manager:
		wave_manager.start_wave()
	on_close_button_pressed()

func on_close_button_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.disable_all_actions(false)
	if player:
		player.block_attacks(false)
	
	# Reseta a posição do item arrastado
	var item = get_tree().get_current_scene().get_node("Player/Invetario/Item")
	if item:
		item.reset_position()
	
	# Fecha (oculta) o inventário
	var inventory = get_tree().get_current_scene().get_node("Player/Invetario")
	if inventory:
		inventory.close()

	emit_signal("menu_closed")
	hide()

func _on_weapons_pressed() -> void:
	back_button.visible = true
	main_menu.visible = false
	weapons_list.visible = true

func _on_build_pressed() -> void:
	main_menu.visible = false
	weapons_list.visible = false
	build_list.visible = true
	items_container.visible = true
	back_button.visible = true
	coins_container.visible = true
	for child in items_container.get_children():
		child.queue_free()
	update_coins_display()
	for key in ItemDatabase.items.keys():
		var item_data = ItemDatabase.get_item_data(key)
		if item_data.size() > 0:
			var item_instance = item_scene.instantiate()
			item_instance.set_item_data(item_data)
			item_instance.connect("item_clicked", Callable(self, "_on_item_clicked"))
			items_container.add_child(item_instance)

func _on_item_clicked(clicked_item_data: Dictionary) -> void:
	items_spec.visible = true
	items_spec.set_item_data(clicked_item_data)

func _on_back_button_pressed() -> void:
	main_menu.visible = true
	back_button.visible = false
	weapons_list.visible = false
	build_list.visible = false
	items_container.visible = false
	items_spec.visible = false
	coins_container.visible = false
	$Update.visible = false
	var inventory = get_tree().get_current_scene().get_node("Player/Invetario")
	if inventory:
		inventory.close()
func update_coins_display() -> void:
	var coins_label = coins_container.get_node("count")
	if coins_label and coins_label is Label:
		coins_label.text = str(GameData.coins)

func _on_leave_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.disable_all_actions(false) 
	emit_signal("menu_closed")
	hide()

# Ao clicar no botão de update (anvil) abre o menu de upgrade
func _on_update_pressed() -> void:
	_show_upgrade_menu()

# Configura e mostra o menu de upgrade
func _show_upgrade_menu() -> void:
	$Update.visible = true
	main_menu.visible = false
	back_button.visible = true
	weapons_list.visible = false
	build_list.visible = false
	items_container.visible = false
	items_spec.visible = false
	coins_container.visible = false
	
	var slot_area = $"Update/Slot/Area2D"
	slot_area.collision_layer = 12
	slot_area.collision_mask = 11
	slot_area.add_to_group("shield")
	slot_area.add_to_group("sword")

	if not slot_area.is_connected("area_entered", Callable(self, "_on_area_2d_area_entered")):
		slot_area.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	if not slot_area.is_connected("area_exited", Callable(self, "_on_area_2d_area_exited")):
		slot_area.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
		
	var slot_node = $Update/Slot
	
	# Conectar o sinal do slot para atualizar o botão
	if not slot_node.is_connected("item_changed", Callable(self, "_on_slot_item_changed")):
		slot_node.connect("item_changed", Callable(self, "_on_slot_item_changed"))
	check_upgrade_button_state()
	update_upgrade_button_text()
	
func _on_slot_item_changed(has_item: bool) -> void:
	check_upgrade_button_state()
	update_upgrade_button_text()
func check_upgrade_button_state() -> void:
	var slot_node = $Update/Slot
	var upgrade_button = $Update/UptadeClick
	
	if slot_node.current_item == null:
		# Desabilita o botão se não houver item no slot
		upgrade_button.disabled = true
		upgrade_button.modulate = Color(1, 1, 1, 0.5)  # Efeito visual de desabilitado
	else:
		# Habilita o botão se houver um item no slot
		upgrade_button.disabled = false
		upgrade_button.modulate = Color(1, 1, 1, 1)  # Normal

func _on_uptade_click_pressed() -> void:
	var slot_node = $Update/Slot
	var dragged_item = slot_node.current_item
	if dragged_item == null:
		print("Não há item no slot para atualizar!")
		return

	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if not wave_manager:
		hide()
		return

	var player = get_tree().get_current_scene().get_node("Player")
	var item_type = dragged_item.get_item_type()
	var current_level = 0
	var next_data = {}

	var arms_db_instance = preload("res://scripts/arms_database.gd").new()

	match item_type:
		"sword_basic":
			current_level = player.sword_level
			next_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, current_level + 1)
		"shield_basic":
			current_level = player.shield_level
			next_data = arms_db_instance.get_weapon_level_data(player.current_shield_id, current_level + 1)
		"spear_basic":
			current_level = player.spear_level
			next_data = arms_db_instance.get_weapon_level_data(player.current_spear_id, current_level + 1)

	if next_data.size() == 0:
		print("Esse item já está no nível máximo ou não existe no DB.")
		hide()
		return

	var needed_wave = next_data.get("wave_required", 9999)

	var upgrade_button = $Update/UptadeClick
	upgrade_button.text = "UPGRADE LV %d" % (current_level + 1)

	if wave_manager.current_wave >= needed_wave:
		player.start_smithing(item_type)
	else:
		print("Wave atual ainda não atinge o requisito:", needed_wave)

	await get_tree().create_timer(0.1).timeout
	on_close_button_pressed()


func update_upgrade_button_text() -> void:
	var slot_node = $Update/Slot
	var dragged_item = slot_node.current_item
	var upgrade_button = $Update/UptadeClick
	var player = get_tree().get_current_scene().get_node("Player")
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()

	if dragged_item == null:
		upgrade_button.text = "UPGRADE"
		return

	var item_type = dragged_item.get_item_type()
	var current_level = 0
	
	match item_type:
		"sword_basic":
			current_level = player.sword_level
		"shield_basic":
			current_level = player.shield_level
		"spear_basic":
			current_level = player.spear_level

	var next_level_data = arms_db_instance.get_weapon_level_data(item_type, current_level + 1)
	if next_level_data.size() == 0:
		upgrade_button.text = "MAX LEVEL"
		upgrade_button.disabled = true
	else:
		upgrade_button.text = "UPGRADE LV %d" % (current_level + 1)
		upgrade_button.disabled = false

# Botão para a espada
func _on_sword_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return
		
	if player.using_spear:
		player.unequip_spear()
		$Weapons/Spear/spear/Text.text = "EQUIP"
		$Weapons/Shield/Shield.disabled = false
		$Weapons/Shield/Shield.modulate = Color(1, 1, 1, 1)
		
	if player.using_sword:
		player.unequip_sword()
		$Weapons/Arm/sword/Text.text = "EQUIP"
	else:
		player.equip_sword()
		$Weapons/Arm/sword/Text.text = "UNEQUIP"
	
	# Atualiza o botão da lança
	$Weapons/Spear/spear/Text.text = "EQUIP"

# Botão para a lança
func _on_spear_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return
		
	if player.using_sword:
		player.unequip_sword()
		$Weapons/Arm/sword/Text.text = "EQUIP"
		
	if player.using_spear:
		player.unequip_spear()
		$Weapons/Spear/spear/Text.text = "EQUIP"
		$Weapons/Shield/Shield.disabled = false
		$Weapons/Shield/Shield.modulate = Color(1, 1, 1, 1)
	else:
		player.equip_spear()
		$Weapons/Spear/spear/Text.text = "UNEQUIP"
		$Weapons/Shield/Shield.disabled = true
		$Weapons/Shield/Shield/Text.text = "EQUIP"
		$Weapons/Shield/Shield.modulate = Color(1, 1, 1, 0.5)
	
	# Atualiza o botão da espada
	$Weapons/Arm/sword/Text.text = "EQUIP"

func _on_spear_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_spear_pressed()

# >>> Botão para o escudo <<<
func _on_shield_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return

	# Se quiser que o escudo seja independente (pode ter espada/lança + escudo), NÃO unequipe nada.
	# Se quiser que o escudo seja exclusivo, comente ou adapte como nas funções de espada/lança.

	if player.using_shield:
		player.unequip_shield()
		$Weapons/Shield/Shield/Text.text = "EQUIP"
	else:
		player.equip_shield()
		$Weapons/Shield/Shield/Text.text = "UNEQUIP"

	# Se quiser permitir wave também só com o escudo, use a linha abaixo:
	start_wave_button.disabled = not (player.using_sword or player.using_spear or player.using_shield)

	# Se NÃO quiser wave só com escudo, mantenha a forma antiga:
	# start_wave_button.disabled = not (player.using_sword or player.using_spear)
