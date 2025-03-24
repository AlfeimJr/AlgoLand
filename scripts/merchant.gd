extends CharacterBody2D

@onready var icon: Sprite2D = $button
@onready var menu_instance: Node2D = $MenuMerchant

var player_in_range: bool = false

signal start_wave_requested

func _ready() -> void:
	add_to_group("merchant")
	icon.visible = false
	menu_instance.visible = false  # Inicialmente oculto
	
	# Conectar sinais do menu
	if menu_instance.has_method("connect_menu_closed"):
		menu_instance.connect_menu_closed(Callable(self, "close_menu"))
	if menu_instance.has_method("connect_start_wave"):
		menu_instance.connect_start_wave(Callable(self, "_on_start_wave_selected"))

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("open_menu"):
		open_menu()
	if menu_instance.visible and Input.is_action_just_pressed("close_menu"):
		close_menu()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("character"):
		player_in_range = true
		icon.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("character"):
		player_in_range = false
		icon.visible = false
		close_menu()

func open_menu() -> void:
	menu_instance.visible = true
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.disable_all_actions(true)
	# Configurar explicitamente as camadas de colisão para slots e itens
	var slots = menu_instance.find_children("*", "Slot", true, false)
	for slot in slots:
		if slot.has_node("Area2D"):
			slot.get_node("Area2D").collision_layer = 12
			slot.get_node("Area2D").collision_mask = 11
	
	var items = menu_instance.find_children("*", "Item", true, false)
	for item in items:
		if item.has_node("Area2D"):
			item.get_node("Area2D").collision_layer = 11
			item.get_node("Area2D").collision_mask = 12

func close_menu() -> void:
	menu_instance.visible = false
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.disable_all_actions(false)
	# Reiniciar estado do menu se necessário
	if menu_instance.has_method("reset_menu"):
		menu_instance.reset_menu()

func _on_start_wave_selected() -> void:
	emit_signal("start_wave_requested")
	close_menu()
