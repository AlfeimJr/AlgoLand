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
@onready var leave_button = $Container/Buttons/Leave
@onready var weapons_option_button = $Container/Buttons/weaponsOption
@onready var build_button = $Container/Buttons/Build

var item_scene = preload("res://cenas/item.tscn")

func _ready() -> void:
	
	update_coins_display()
	var wave_manager = get_tree().get_root().get_node("cenario/enemySpawner/WaveManager")
	if wave_manager and wave_manager.is_wave_running:
		queue_free()
		return
	if start_wave_button:
		start_wave_button.disabled = true
		start_wave_button.connect("pressed", Callable(self, "_on_start_wave_pressed"))
	if weapons_option_button:
		weapons_option_button.connect("pressed", Callable(self, "_on_weapons_pressed"))
	if $Container/Weapons/Sword:
		$Container/Weapons/Sword.connect("pressed", Callable(self, "_on_sword_pressed"))
	if build_button:
		build_button.connect("pressed", Callable(self, "_on_build_pressed"))
	if back_button:
		back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))
	if leave_button:
		leave_button.connect("pressed", Callable(self, "_on_leave_pressed"))
	var player = get_tree().get_current_scene().get_node("Player")
	if player and player.using_sword:
		start_wave_button.disabled = false

func _process(delta: float) -> void:
	var player = get_tree().get_current_scene().get_node("Player")
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
		$Container/Weapons/Arm/Button/Text.text = 'UNEQUIP'
	else:
		$Container/Weapons/Arm/Button/Text.text = 'EQUIP'
	if start_wave_button:
		start_wave_button.disabled = not player.using_sword

func _on_start_wave_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
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

func update_coins_display() -> void:
	var coins_label = coins_container.get_node("count")
	if coins_label and coins_label is Label:
		coins_label.text = str(GameData.coins)

func _on_leave_pressed() -> void:
	emit_signal("menu_closed")
	queue_free()
