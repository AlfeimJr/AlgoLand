extends Node2D

@onready var main = get_node("/root/cenario")
signal hit_p

# Lista de cenas de inimigos que podem ser instanciadas
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://cenas/inimigos/slime.tscn"),
]

var spawn_points := []
var wave_manager
@export var spawn_delay: float = 0.5

# Função auxiliar para verificar se o objeto possui a propriedade
func has_property(obj: Object, property_name: String) -> bool:
	for prop in obj.get_property_list():
		if prop.name == property_name:
			return true
	return false

func _ready() -> void:
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
	if enemy_scenes.size() == 0:
		return false
	
	# Escolhe uma cena de inimigo aleatoriamente
	var random_index = randi() % enemy_scenes.size()
	var enemy_scene = enemy_scenes[random_index]
	
	var enemy = enemy_scene.instantiate()
	if enemy == null:
		return false

	enemy.name = "Enemy_" + str(randi() % 1000)
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	enemy.position = spawn.global_position + offset

	# Ajusta os atributos, se o inimigo possuir as propriedades
	if has_property(enemy, "health"):
		enemy.health *= health_multiplier
	if has_property(enemy, "damage"):
		enemy.damage *= damage_multiplier

	# Adiciona o inimigo à cena principal
	if is_instance_valid(main):
		main.add_child(enemy)
	else:
		return false

	# Configura as camadas de colisão:
	# Define que o inimigo estará nas camadas 3 e 4
	# (lembre-se: layer 3 -> bit 2, layer 4 -> bit 3)
	if enemy is CollisionObject2D:
		enemy.collision_layer = (1 << 2) | (1 << 3)
		# Define a máscara para detectar colisões nas camadas 1 a 10
		enemy.collision_mask = (1 << 10) - 1  # (2¹⁰ - 1 = 1023)
	
	await get_tree().process_frame
	if not enemy.is_inside_tree():
		return false

	enemy.add_to_group("enemy")
	if wave_manager and is_instance_valid(wave_manager):
		enemy.connect("enemy_died", Callable(wave_manager, "enemy_died"))
	if enemy.has_method("verify_lifespan"):
		enemy.call_deferred("verify_lifespan")

	# Ativa/desativa a colisão para evitar problemas iniciais
	# Certifique-se de usar o nome correto do nó; neste exemplo, usamos "collision_body"
	if enemy.has_node("collision_body"):
		var collision = enemy.get_node("collision_body")
		print(collision)
		if collision and is_instance_valid(collision):
			collision.set_deferred("disabled", true)
			await get_tree().process_frame
			if is_instance_valid(collision):
				collision.set_deferred("disabled", false)
	return true
