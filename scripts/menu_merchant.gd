extends CanvasLayer

signal menu_closed
@export var detection_distance: float = 200.0

@onready var main_menu: Control = $Container/Buttons
@onready var weapons_list: Control = $Container/Weapons
@onready var build_list: Control = $Container/ItemsContainer
@onready var items_container = $Container/ItemsContainer
@onready var items_spec = $Container/ItemSpec
@onready var back_button = $Container/BackButton
@onready var coins_container = $Container/Coins
@onready var start_wave_button: Button = $Container/Buttons/StartWave
@onready var update_button: Button = $Container/Buttons/Update
@onready var leave_button: Button = $Container/Buttons/Leave
@onready var weapons_option_button: Button = $Container/Buttons/weaponsOption
@onready var build_button: Button = $Container/Buttons/Build

# ContainerArms: exibe arma atual e próxima arma
@onready var actual_arm_sprite: Sprite2D = $Container/Update/ContainerArms/ActualArm/Arm
@onready var next_level_arm_sprite: Sprite2D = $Container/Update/ContainerArms/NextLevelArm/Arm

@onready var level_label: Label = $Container/Update/Level
@onready var alert_label: Label = $Container/Update/Alert

var item_scene = preload("res://cenas/item.tscn")

# Mantemos o dicionário de waves para mensagens
var wave_thresholds = {
	1: 4,   # libera lvl 2 na wave 4
	2: 9,   # libera lvl 3 na wave 9
	3: 20,  # libera lvl 4 na wave 20
	4: 35   # libera lvl 5 na wave 35
}

func _ready() -> void:
	update_coins_display()
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if wave_manager and wave_manager.is_wave_running:
		queue_free()
		return
	
	if start_wave_button and not start_wave_button.is_connected("pressed", Callable(self, "_on_start_wave_pressed")):
		start_wave_button.disabled = true
		start_wave_button.connect("pressed", Callable(self, "_on_start_wave_pressed"))

	if weapons_option_button and not weapons_option_button.is_connected("pressed", Callable(self, "_on_weapons_pressed")):
		weapons_option_button.connect("pressed", Callable(self, "_on_weapons_pressed"))

	if has_node("Container/Weapons/Sword"):
		var sword_button = $Container/Weapons/Sword
		if sword_button and not sword_button.is_connected("pressed", Callable(self, "_on_sword_pressed")):
			sword_button.connect("pressed", Callable(self, "_on_sword_pressed"))

	if build_button and not build_button.is_connected("pressed", Callable(self, "_on_build_pressed")):
		build_button.connect("pressed", Callable(self, "_on_build_pressed"))

	if back_button and not back_button.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))

	if leave_button and not leave_button.is_connected("pressed", Callable(self, "_on_leave_pressed")):
		leave_button.connect("pressed", Callable(self, "_on_leave_pressed"))
	
	var player = get_tree().get_current_scene().get_node("Player")
	if player and player.using_sword:
		start_wave_button.disabled = false
	if player:
		if player.using_sword:
			$Container/Weapons/Arm/Button/Text.text = "UNEQUIP"
		else:
			$Container/Weapons/Arm/Button/Text.text = "EQUIP"
func _process(delta: float) -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		update_button.disabled = not player.using_sword
		start_wave_button.disabled = not player.using_sword
	var merchant = get_tree().get_root().get_node("cenario/Merchant")
	if player and merchant:
		if player.global_position.distance_to(merchant.global_position) > detection_distance:
			on_close_button_pressed()

func _on_button_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if not player:
		return
	player.equip_sword_and_shield()
	if player.using_sword:
		$Container/Weapons/Arm/Button/Text.text = "UNEQUIP"
	else:
		$Container/Weapons/Arm/Button/Text.text = "EQUIP"

	if start_wave_button:
		start_wave_button.disabled = not player.using_sword

func _on_start_wave_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	print("Start wave pressed, using_sword:", player.using_sword)
	if player and not player.using_sword:
		return
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if wave_manager:
		wave_manager.start_wave()
	on_close_button_pressed()

func on_close_button_pressed() -> void:
	emit_signal("menu_closed")
	queue_free()

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
	# Aqui segue o carregamento dos itens; ajuste se necessário.
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
	$Container/Update.visible = false

func update_coins_display() -> void:
	var coins_label = coins_container.get_node("count")
	if coins_label and coins_label is Label:
		coins_label.text = str(GameData.coins)

func _on_leave_pressed() -> void:
	emit_signal("menu_closed")
	queue_free()

### Funções de Upgrade (Smithing) usando arms_database

func _on_update_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if not player or not wave_manager:
		return
	
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()

	# Espada
	var next_sword_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, player.sword_level + 1)
	var current_sword_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, player.sword_level)

	# Escudo
	var next_shield_data = arms_db_instance.get_weapon_level_data(player.current_shield_id, player.shield_level + 1)
	var current_shield_data = arms_db_instance.get_weapon_level_data(player.current_shield_id, player.shield_level)

	# Se não existir próximo nível de espada OU escudo, exibe "Full" (ajuste conforme desejar)
	if next_sword_data.size() == 0 or next_shield_data.size() == 0:
		level_label.text = "Full"
		# ...
		return

	# Caso contrário, mostra texturas da espada e do escudo atual e do próximo nível
	if current_sword_data.has("texture"):
		actual_arm_sprite.texture = current_sword_data["texture"]
	if next_sword_data.has("texture"):
		next_level_arm_sprite.texture = next_sword_data["texture"]
	
	# Supondo que você tenha “actual_shield_sprite” e “next_level_shield_sprite” no menu
	if current_shield_data.has("texture"):
		$Container/Update/ContainerArms/ActualShield/Arm.texture = current_shield_data["texture"]
	if next_shield_data.has("texture"):
		$Container/Update/ContainerArms/NextLevelShield/Arm.texture = next_shield_data["texture"]

	# wave_required (assumindo que ambos precisam do mesmo wave_required, ou pegue o maior se quiser)
	var needed_wave = max(
		next_sword_data.get("wave_required", 9999),
		next_shield_data.get("wave_required", 9999)
	)
	level_label.text = "UPGRADE LV " + str(player.sword_level + 1)
	alert_label.text = "OPENS BY WINNING WAVE " + str(needed_wave)

	_show_upgrade_menu()

func _show_upgrade_menu() -> void:
	$Container/Update.visible = true
	main_menu.visible = false
	back_button.visible = true
	weapons_list.visible = false
	build_list.visible = false
	items_container.visible = false
	items_spec.visible = false
	coins_container.visible = false

func _on_uptade_click_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if not player or not wave_manager:
		queue_free()
		return
	
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var next_data = arms_db_instance.get_weapon_level_data(player.current_weapon_id, player.sword_level + 1)
	if next_data.size() == 0:
		level_label.text = "Full"
		queue_free()
		return
	
	var needed_wave = next_data.get("wave_required", 9999)
	if wave_manager.current_wave >= needed_wave:
		# Realiza o upgrade chamando start_smithing() do player
		player.start_smithing()
		# Se após o upgrade não houver próximo nível, exibe "Full"
		var check_next = arms_db_instance.get_weapon_level_data(player.current_weapon_id, player.sword_level + 1)
		if check_next.size() == 0:
			level_label.text = "Full"
	else:
		return
	
	queue_free()
