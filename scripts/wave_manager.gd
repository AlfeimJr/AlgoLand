extends Node

signal wave_started(wave: int)
signal wave_completed(wave: int)
signal game_won()  

@export var starting_wave: int = 1
@export var max_enemies: int = 50
@export var wave_interval: float = 15.0
@export var max_waves: int = 10
@export var detection_increase_per_wave: float = 0.2

const MAX_ACTIVE_ENEMIES: int = 50

# Em vez de usar um Rect2 para a área de spawn, exporte um NodePath para o Area2D
@export var spawn_area_path = NodePath("../../SpawnArea")

var current_wave: int = 1
var enemies_alive: int = 0
var enemies_spawned: int = 0
var enemy_health_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var spawner
var waves_stopped: bool = false

var spawn_area: Area2D

func _ready() -> void:
	await get_tree().process_frame
	current_wave = starting_wave
	spawner = get_tree().get_root().get_node("cenario/enemySpawner")
	spawn_area = get_node(spawn_area_path)

func start_wave() -> void:
	if waves_stopped:
		return

	if current_wave > max_waves:
		emit_signal("game_won")
		return

	emit_signal("wave_started", current_wave)
	enemies_spawned = 0
	# Fórmula: onda 1 terá 'max_enemies'; ondas seguintes aumentam geometricamente (multiplicador 1.5)
	enemies_alive = int(max_enemies * pow(1.5, current_wave - 1))
	enemy_health_multiplier = 1.0 + (current_wave * 0.2)
	enemy_damage_multiplier = 1.0 + (current_wave * 0.1)
	
	# Define a escala de detecção para esta wave:
	# Ex.: wave 1 = 1.0, wave 2 = 1.0 + detection_increase_per_wave, etc.
	var detection_scale = 1.0 + (current_wave - 1) * detection_increase_per_wave

	var wave_banner = get_tree().get_root().get_node("cenario/UI/wave")
	if wave_banner:
		wave_banner.show_wave_number(current_wave)

	update_ui()
	# Passa a detection_scale para o spawn dos inimigos
	spawn_enemies(enemies_alive, enemy_health_multiplier, enemy_damage_multiplier, detection_scale)

func update_ui() -> void:
	var ui = get_tree().get_root().get_node("cenario/UI")
	if ui:
		ui.enemies_label.text = "Enemys: " + str(enemies_alive)

func spawn_enemies(num_enemies: int, health_multiplier: float, damage_multiplier: float, detection_scale: float) -> void:
	if spawner.spawn_points.is_empty():
		return
	
	spawner.spawn_points.shuffle()
	
	for i in range(num_enemies):
		while get_tree().get_nodes_in_group("enemy").size() >= MAX_ACTIVE_ENEMIES:
			await get_tree().create_timer(0.5).timeout
		
		var spawn_position = get_random_position_in_area()
		if spawn_position != Vector2.ZERO:
			spawn_enemy(spawn_position, health_multiplier, damage_multiplier, detection_scale)
		
		await get_tree().create_timer(0.1).timeout
	
	enemies_alive = get_tree().get_nodes_in_group("enemy").size()

func get_random_position_in_area() -> Vector2:
	if spawn_area == null:
		return Vector2.ZERO

	var collision = spawn_area.get_node("CollisionShape2D")
	if collision and collision.shape is RectangleShape2D:
		var rect_shape = collision.shape as RectangleShape2D
		var extents = rect_shape.extents
		var random_local = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
		var global_pos = spawn_area.global_position + random_local
		return global_pos
	else:
		return spawn_area.global_position

func spawn_enemy(position: Vector2, health_multiplier: float, damage_multiplier: float, detection_scale: float) -> void:
	if position == Vector2.ZERO:
		return

	var slime = preload("res://cenas/slime.tscn").instantiate()
	if slime == null:
		return

	slime.position = position
	slime.health *= health_multiplier
	slime.damage *= damage_multiplier

	get_tree().get_root().get_node("cenario").add_child(slime)
	slime.add_to_group("enemy")
	slime.connect("enemy_died", Callable(self, "enemy_died"))

	# Chama o método do Slime para aumentar a área de detecção
	slime.call_deferred("set_detection_scale", detection_scale)

	configure_enemy_collision(slime)

func configure_enemy_collision(enemy):
	# Configure colisões conforme sua necessidade.
	pass

func enemy_died() -> void:
	enemies_alive -= 1
	update_ui()

	if enemies_alive <= 0:
		emit_signal("wave_completed", current_wave)
		if waves_stopped:
			return
		await get_tree().create_timer(wave_interval).timeout
		if waves_stopped:
			return
		current_wave += 1
		start_wave()

func stop_waves() -> void:
	waves_stopped = true
	var enemy_list = get_tree().get_nodes_in_group("enemy")
	for enemy in enemy_list:
		enemy.queue_free()
	current_wave = starting_wave
	enemies_alive = 0
	update_ui()
