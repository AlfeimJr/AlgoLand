extends Node2D

@onready var main = get_node("/root/cenario")
signal hit_p
var slime_scene := preload("res://cenas/slime.tscn")
var spawn_points := []
var wave_manager
@export var spawn_delay: float = 0.5

func _ready():
	await get_tree().process_frame
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	wave_manager = main.get_node("enemySpawner/WaveManager")
	if wave_manager:
		wave_manager.spawner = self

func spawn_enemies(num_enemies: int, health_multiplier: float, damage_multiplier: float) -> void:
	if spawn_points.size() == 0:
		return
	
	var total_spawned: int = 0
	while total_spawned < num_enemies:
		if wave_manager and wave_manager.waves_stopped:
			return
		var spawn_point = get_random_spawn_point()
		var success = await spawn_enemy_at(spawn_point, health_multiplier, damage_multiplier)
		if success:
			total_spawned += 1
		if wave_manager and wave_manager.waves_stopped:
			return
		
		await get_tree().create_timer(spawn_delay).timeout
	
	if wave_manager:
		wave_manager.enemies_alive = total_spawned

func get_random_spawn_point() -> Marker2D:
	var index = randi() % spawn_points.size()
	return spawn_points[index]

func spawn_enemy_at(spawn: Marker2D, health_multiplier: float, damage_multiplier: float) -> bool:
	if spawn == null or not is_instance_valid(spawn):
		return false

	var slime = slime_scene.instantiate()
	if slime == null:
		return false

	slime.name = "Slime_" + str(randi() % 1000)
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	slime.position = spawn.global_position + offset

	if slime.has_variable("health"):
		slime.health *= health_multiplier
	if slime.has_variable("damage"):
		slime.damage *= damage_multiplier

	if is_instance_valid(main):
		main.add_child(slime)
	else:
		return false

	await get_tree().process_frame
	if not slime.is_inside_tree():
		return false

	slime.add_to_group("enemy")
	if wave_manager and is_instance_valid(wave_manager):
		slime.connect("enemy_died", Callable(wave_manager, "enemy_died"))
	if slime.has_method("verify_lifespan"):
		slime.call_deferred("verify_lifespan")

	if slime.has_node("CollisionShape2D"):
		var collision = slime.get_node("CollisionShape2D")
		if collision and is_instance_valid(collision):
			collision.set_deferred("disabled", true)
			await get_tree().process_frame
			if is_instance_valid(collision):
				collision.set_deferred("disabled", false)
	return true
