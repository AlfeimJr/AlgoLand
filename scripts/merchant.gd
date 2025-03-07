extends CharacterBody2D

@onready var icon: Sprite2D = $button  # Ícone que aparece quando o jogador está próximo
var player_in_range: bool = false     # Controla se o jogador está na área de detecção
var menu_instance: CanvasLayer = null # Referência ao menu aberto

signal start_wave_requested

func _ready() -> void:
	add_to_group("merchant")
	icon.visible = false
	var area_2d = $Area2D
	if area_2d:
		if not area_2d.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
			area_2d.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
		if not area_2d.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
			area_2d.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("open_menu"):
		_on_open_menu_pressed()
	if menu_instance != null and Input.is_action_just_pressed("close_menu"):
		close_menu()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("character"):
		player_in_range = true
		icon.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("character"):
		player_in_range = false
		icon.visible = false
		if menu_instance != null:
			close_menu()

func _on_open_menu_pressed() -> void:
	var menu_scene = preload("res://cenas/menu_merchant.tscn")
	menu_instance = menu_scene.instantiate()
	add_child(menu_instance)
	if menu_instance.has_method("connect_menu_closed"):
		menu_instance.connect_menu_closed(Callable(self, "close_menu"))
	if menu_instance.has_method("connect_start_wave"):
		menu_instance.connect_start_wave(Callable(self, "_on_start_wave_selected"))

func close_menu() -> void:
	if menu_instance != null:
		menu_instance.queue_free()
		menu_instance = null

func _on_start_wave_selected() -> void:
	emit_signal("start_wave_requested")
