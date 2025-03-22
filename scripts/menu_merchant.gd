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

var item_scene = preload("res://cenas/item.tscn")

var wave_thresholds = {
	1: 4,   # libera lvl 2 na wave 4
	2: 9,   # libera lvl 3 na wave 9
	3: 20,  # libera lvl 4 na wave 20
	4: 35   # libera lvl 5 na wave 35
}

func _ready() -> void:
	var slot_world = $Update/Slot.get_viewport().get_world_2d()
	var item = get_tree().get_root().get_node("cenario/Player/Invetario/Item")
	print("Slot World ID: ", slot_world.get_instance_id())
	print("item world:", item.get_instance_id())
	var inventory = get_tree().get_root().get_node("cenario/Player/Invetario")
	print(inventory)
	if inventory:
		inventory.connect("item_selected", Callable(self, "_on_inventory_item_selected"))
	update_coins_display()

	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if wave_manager and wave_manager.is_wave_running:
		hide()  # Oculta o menu se a wave estiver em execução
		return
	
	# Conecta botões principais
	if start_wave_button and not start_wave_button.is_connected("pressed", Callable(self, "_on_start_wave_pressed")):
		start_wave_button.disabled = true
		start_wave_button.connect("pressed", Callable(self, "_on_start_wave_pressed"))

	if weapons_option_button and not weapons_option_button.is_connected("pressed", Callable(self, "_on_weapons_pressed")):
		weapons_option_button.connect("pressed", Callable(self, "_on_weapons_pressed"))

	# Botão da Espada
	if has_node("Container/Weapons/Sword"):
		var sword_button = $Container/Weapons/Sword
		if sword_button and not sword_button.is_connected("pressed", Callable(self, "_on_sword_pressed")):
			sword_button.connect("pressed", Callable(self, "_on_sword_pressed"))
			
	# Botão da Lança
	if has_node("Container/Weapons/Spear"):
		var spear_button = $Container/Weapons/Spear
		if spear_button:
			if spear_button is Button:
				if not spear_button.is_connected("pressed", Callable(self, "_on_spear_pressed")):
					spear_button.connect("pressed", Callable(self, "_on_spear_pressed"))
			else:
				# Se o nó não for Button, usar gui_input
				if not spear_button.is_connected("gui_input", Callable(self, "_on_spear_gui_input")):
					spear_button.connect("gui_input", Callable(self, "_on_spear_gui_input"))
	
	if build_button and not build_button.is_connected("pressed", Callable(self, "_on_build_pressed")):
		build_button.connect("pressed", Callable(self, "_on_build_pressed"))

	if back_button and not back_button.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))

	if leave_button and not leave_button.is_connected("pressed", Callable(self, "_on_leave_pressed")):
		leave_button.connect("pressed", Callable(self, "_on_leave_pressed"))
	
	
	if player:
		# Se o player estiver usando a espada
		if player.using_sword:
			start_wave_button.disabled = false
			$Weapons/Arm/Button/Text.text = "UNEQUIP"
		else:
			$Weapons/Arm/Button/Text.text = "EQUIP"

		# Se o player estiver usando a lança
		if player.using_spear:
			$Weapons/Spear/spear/Text.text = "UNEQUIP"
		else:
			$Weapons/Spear/spear/Text.text = "EQUIP"
		
		player.block_attacks(true)

func _on_inventory_item_selected(item_type: String, texture: Texture2D) -> void:
	# Atualiza algo quando seleciona item no inventário
	print(texture)
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var player = get_tree().get_current_scene().get_node("Player")

	var current_level = 0
	var next_level = 0
	if item_type == "sword":
		current_level = player.sword_level
		next_level = current_level + 1
	elif item_type == "shield":
		current_level = player.shield_level
		next_level = current_level + 1

	var next_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, next_level)
	print(player.current_weapon_id)
	if next_data.size() > 0:
		var needed_wave = next_data.get("wave_required", 9999)
		alert_label.text = "OPENS BY WINNING WAVE " + str(needed_wave)
	else:
		alert_label.text = "MAX LEVEL REACHED"

func _process(delta: float) -> void:
	
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		# Habilita os botões se o player estiver usando alguma arma
		update_button.disabled = not (player.using_sword or player.using_spear)
		start_wave_button.disabled = not (player.using_sword or player.using_spear)

	var merchant = get_tree().get_root().get_node("cenario/Merchant")
	if player and merchant:
		if player.global_position.distance_to(merchant.global_position) > detection_distance:
			on_close_button_pressed()

func _on_button_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return
	player.equip_sword()

	if player.using_sword:
		$Weapons/Arm/Button/Text.text = "UNEQUIP"
	else:
		$Weapons/Arm/Button/Text.text = "EQUIP"

	if start_wave_button:
		start_wave_button.disabled = not player.using_sword

func _on_start_wave_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	print("Start wave pressed, using_sword:", player.using_sword)
	if player and not (player.using_sword or player.using_spear):
		return

	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if wave_manager:
		wave_manager.start_wave()
	on_close_button_pressed()

func on_close_button_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.block_attacks(false)
	var item = get_tree().get_current_scene().get_node("Player/Invetario/Item")
	if item:
		item.reset_position()  # Chama a função do item
	emit_signal("menu_closed")
	hide()  # Oculta o menu em vez de liberá-lo

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

func update_coins_display() -> void:
	var coins_label = coins_container.get_node("count")
	if coins_label and coins_label is Label:
		coins_label.text = str(GameData.coins)

func _on_leave_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.block_attacks(false)
	emit_signal("menu_closed")
	hide()  # Oculta o menu

func _on_update_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if not player or not wave_manager:
		return

	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var next_sword_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, player.sword_level + 1)
	var next_shield_data = arms_db_instance.get_weapon_level_data(player.current_shield_id, player.shield_level + 1)
	var needed_wave = max(
		next_sword_data.get("wave_required", 9999),
		next_shield_data.get("wave_required", 9999)
	)
	alert_label.text = "OPENS BY WINNING WAVE " + str(needed_wave)
	_show_upgrade_menu()

func _show_upgrade_menu() -> void:
	$Update.visible = true
	main_menu.visible = false
	back_button.visible = true
	weapons_list.visible = false
	build_list.visible = false
	items_container.visible = false
	items_spec.visible = false
	coins_container.visible = false
	var teste = $"Update/Slot/Area2D"
	var colision = $"Update/Slot/Area2D/CollisionShape2D" 
	teste.collision_layer = 12 
	teste.collision_mask = 11 
	teste.add_to_group('shield')
	teste.add_to_group('sword')
	teste.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	teste.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	

func _on_uptade_click_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if not player or not wave_manager:
		hide()
		return

	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var next_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, player.sword_level + 1)
	if next_data.size() == 0:
		hide()
		return

	var needed_wave = next_data.get("wave_required", 9999)
	if wave_manager.current_wave >= needed_wave:
		player.start_smithing()
		# ...
	else:
		return
	hide()

# Botão para a espada
func _on_sword_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return

	# Se estiver usando a lança, desequipa
	if player.using_spear:
		player.unequip_spear()
		$Weapons/Spear/spear/Text.text = "EQUIP"

	# Toggle da espada
	if player.using_sword:
		player.unequip_sword()
		$Weapons/Arm/Button/Text.text = "EQUIP"
	else:
		player.equip_sword()
		$Weapons/Arm/Button/Text.text = "UNEQUIP"

	start_wave_button.disabled = not (player.using_sword or player.using_spear)

# Botão para a lança
func _on_spear_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return

	# Se estiver usando a espada, desequipa
	if player.using_sword:
		player.unequip_sword()
		$Weapons/Arm/Button/Text.text = "EQUIP"

	# Toggle da lança
	if player.using_spear:
		player.unequip_spear()
		$Weapons/Spear/spear/Text.text = "EQUIP"
	else:
		player.equip_spear()
		$Weapons/Spear/spear/Text.text = "UNEQUIP"

	start_wave_button.disabled = not (player.using_sword or player.using_spear)

func _on_spear_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_spear_pressed()
