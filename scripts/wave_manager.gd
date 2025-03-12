extends Node

signal wave_started(wave: int)
signal wave_completed(wave: int)
signal game_won()
signal waves_stopped_signal
@export var starting_wave: int = 35
@export var max_enemies: int = 5
@export var wave_interval: float = 15.0
@export var max_waves: int = 1000
@export var detection_increase_per_wave: float = 0.2
@export var gold_base_reward: int = 100
@onready var merchant = $"../../Merchant"
const MAX_ACTIVE_ENEMIES: int = 50
@export var spawn_area_path: NodePath = NodePath("/root/cenario/SpawnArea")

var current_wave: int = 1
var enemies_alive: int = 0
var spawner
var spawn_area: Area2D
var waves_stopped: bool = false

var enemy_health_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0

var is_wave_running: bool = false

@onready var player = get_node("/root/cenario/Player")

func _ready() -> void:
	await get_tree().create_timer(0.0).timeout
	current_wave = starting_wave
	spawner = get_tree().get_root().get_node("/root/cenario/enemySpawner")
	spawn_area = get_node(spawn_area_path)

func start_wave() -> void:
	waves_stopped = false
	if player.isDead:
		current_wave = 1
		player.isDead = false
	if waves_stopped:
		return
	if current_wave > max_waves:
		emit_signal("game_won")
		return
	emit_signal("wave_started", current_wave)
	merchant.visible = false
	is_wave_running = true
	enemies_alive = int(max_enemies * pow(1.5, current_wave - 1))
	enemy_health_multiplier = 1.0 + (current_wave * 0.2)
	enemy_damage_multiplier = 1.0 + (current_wave * 0.1)
	var detection_scale = 1.0 + (current_wave - 1) * detection_increase_per_wave
	var wave_banner = get_tree().get_root().get_node("cenario/UI/wave")
	if wave_banner:
		wave_banner.show_wave_number(current_wave)
	update_ui()
	spawn_enemies(enemies_alive, enemy_health_multiplier, enemy_damage_multiplier, detection_scale)

func update_ui() -> void:
	var ui = get_tree().get_root().get_node("cenario/UI")
	if ui:
		ui.enemies_label.text = "Enemies: " + str(enemies_alive)

func spawn_enemies(num_enemies: int, health_multiplier: float, damage_multiplier: float, detection_scale: float) -> void:
	if not spawner or spawner.spawn_points.is_empty():
		return
	spawner.spawn_points.shuffle()
	for i in range(num_enemies):
		if waves_stopped:
			return
		while get_tree().get_nodes_in_group("enemy").size() >= MAX_ACTIVE_ENEMIES:
			if waves_stopped:
				return
			await get_tree().create_timer(0.5).timeout
		if waves_stopped:
			return
		var spawn_position = get_random_position_in_area()
		if spawn_position != Vector2.ZERO:
			spawn_enemy(spawn_position, health_multiplier, damage_multiplier, detection_scale)
		await get_tree().create_timer(0.1).timeout
	enemies_alive = get_tree().get_nodes_in_group("enemy").size()

func get_random_position_in_area() -> Vector2:
	if not spawn_area:
		return Vector2.ZERO
	var collision = spawn_area.get_node("CollisionShape2D")
	if collision and collision.shape is RectangleShape2D:
		var rect_shape = collision.shape as RectangleShape2D
		var extents = rect_shape.extents
		var random_local = Vector2(randf_range(-extents.x, extents.x), randf_range(-extents.y, extents.y))
		return spawn_area.global_position + random_local
	else:
		return spawn_area.global_position

func spawn_enemy(position: Vector2, health_multiplier: float, damage_multiplier: float, detection_scale: float) -> void:
	if position == Vector2.ZERO:
		return
	var slime_scene = preload("res://cenas/slime.tscn")
	if not slime_scene:
		return
	var slime = slime_scene.instantiate()
	slime.position = position
	slime.health *= health_multiplier
	slime.damage *= damage_multiplier
	get_tree().get_root().get_node("cenario").add_child(slime)
	slime.add_to_group("enemy")
	slime.connect("enemy_died", Callable(self, "enemy_died"))
	slime.call_deferred("set_detection_scale", detection_scale)
	configure_enemy_collision(slime)

func configure_enemy_collision(enemy: Node) -> void:
	pass

func enemy_died() -> void:
	enemies_alive -= 1
	update_ui()
	if enemies_alive <= 0:
		var reward = gold_base_reward * current_wave
		GameData.add_coins(reward)
		merchant.visible = true
		var store = get_tree().get_root().get_node_or_null("cenario/UI/MerchantMenu")
		if store and store.is_visible():
			store.update_coins_display()
		is_wave_running = false
		emit_signal("wave_completed", current_wave)
		current_wave += 1

func stop_waves() -> void:
	waves_stopped = true
	emit_signal("waves_stopped_signal")
	merchant.visible = true
	var enemy_list = get_tree().get_nodes_in_group("enemy")
	for enemy in enemy_list:
		enemy.queue_free()
	current_wave = 1
	enemies_alive = 0
	is_wave_running = false
	var ui = get_tree().get_root().get_node("cenario/UI")
	if ui:
		ui.enemies_label.text = "Enemies"
