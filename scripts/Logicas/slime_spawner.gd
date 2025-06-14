extends Node2D

@onready var main = get_node("/root/cenario")
signal hit_p

@export var enemy_scenes: Array[PackedScene] = [
	preload("res://cenas/inimigos/slime.tscn"),
]

var spawn_points := []
var wave_manager
@export var spawn_delay: float = 0.5
@export var max_spawn_attempts: int = 3
@export var prevent_consecutive_spawns: bool = true
var last_spawn_index: int = -1

func has_property(obj: Object, property_name: String) -> bool:
	for prop in obj.get_property_list():
		if prop.name == property_name:
			return true
	return false

func _ready() -> void:
	randomize()
	await get_tree().process_frame
	# Coleta todos os pontos de spawn
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	# Obtém o WaveManager a partir do main
	if is_instance_valid(main):
		wave_manager = main.get_node("enemySpawner/WaveManager")
		if wave_manager:
			wave_manager.spawner = self
	else:
		push_error("Main node not found or invalid")

func spawn_enemies(num_enemies: int, health_multiplier: float, damage_multiplier: float) -> void:
	if spawn_points.size() == 0:
		push_error("No spawn points available")
		return
	
	var total_spawned: int = 0
	while total_spawned < num_enemies:
		if wave_manager and wave_manager.waves_stopped:
			return
		
		var spawn_point = get_better_spawn_point()
		var success = await spawn_enemy_with_retry(spawn_point, health_multiplier, damage_multiplier)
		if success:
			total_spawned += 1
		if wave_manager and wave_manager.waves_stopped:
			return
		await get_tree().create_timer(spawn_delay).timeout
	
	# Não sobrescreva o contador de inimigos; o WaveManager já o definiu no início da wave.
	# if is_instance_valid(wave_manager):
	#     wave_manager.enemies_alive = total_spawned

func spawn_enemy_with_retry(spawn: Marker2D, health_multiplier: float, damage_multiplier: float) -> bool:
	var attempts = 0
	while attempts < max_spawn_attempts:
		var result = await spawn_enemy_at(spawn, health_multiplier, damage_multiplier)
		if result:
			return true
		attempts += 1
		await get_tree().create_timer(0.1).timeout
	return false

func get_better_spawn_point() -> Marker2D:
	if spawn_points.size() <= 1:
		return spawn_points[0]
	
	var index: int
	if prevent_consecutive_spawns and spawn_points.size() > 1:
		var available_indices = range(spawn_points.size())
		if last_spawn_index != -1:
			available_indices.erase(last_spawn_index)
		index = available_indices[randi() % available_indices.size()]
	else:
		index = randi() % spawn_points.size()
	
	last_spawn_index = index
	return spawn_points[index]

func get_random_spawn_point() -> Marker2D:
	var index = randi() % spawn_points.size()
	return spawn_points[index]

func spawn_enemy_at(spawn: Marker2D, health_multiplier: float, damage_multiplier: float) -> bool:
	# Verificações de segurança
	if spawn == null or not is_instance_valid(spawn):
		push_error("Invalid spawn point")
		return false
	
	if enemy_scenes.size() == 0:
		push_error("No enemy scenes available")
		return false
	
	if not is_instance_valid(main):
		push_error("Main scene is not valid")
		return false
	
	var random_index = randi() % enemy_scenes.size()
	var enemy_scene = enemy_scenes[random_index]
	if enemy_scene == null:
		push_error("Selected enemy scene is null")
		return false
	
	var enemy = enemy_scene.instantiate()
	if enemy == null:
		push_error("Failed to instantiate enemy")
		return false

	enemy.name = "Enemy_" + str(randi() % 10000)
	var enemy_name = enemy.name  # Armazena o nome para referência
	var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	enemy.position = spawn.global_position + offset

	if has_property(enemy, "health"):
		enemy.health *= health_multiplier
	if has_property(enemy, "damage"):
		enemy.damage *= damage_multiplier

	main.add_child(enemy)
	enemy.z_index = 10
	if enemy.has_node("Sprite2D"):
		var sprite = enemy.get_node("Sprite2D")
		sprite.modulate.a = 1.0
	
	# Aguarda um frame para garantir que o inimigo foi adicionado
	await get_tree().process_frame
	if not is_instance_valid(enemy) or not enemy.is_inside_tree():
		push_error("Enemy was not properly added to the scene tree")
		if is_instance_valid(enemy) and enemy.get_parent() == null:
			enemy.queue_free()
		return false

	if enemy is CollisionObject2D:
		enemy.collision_layer = (1 << 2) | (1 << 3)
		enemy.collision_mask = (1 << 10) - 1
	
	enemy.add_to_group("enemy")
	if is_instance_valid(wave_manager):
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", Callable(wave_manager, "enemy_died"))
		else:
			push_warning("Enemy does not have 'enemy_died' signal")
	
	if enemy.has_method("verify_lifespan"):
		enemy.call_deferred("verify_lifespan")
	
	if enemy.has_node("collision_body"):
		var collision = enemy.get_node("collision_body")
		if is_instance_valid(collision):
			collision.set_deferred("disabled", true)
			await get_tree().process_frame
			if is_instance_valid(collision):
				collision.set_deferred("disabled", false)
	
	var timer = get_tree().create_timer(1.0)
	await timer.timeout
	
	return true
