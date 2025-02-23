extends Node2D

@onready var main = get_node("/root/cenario")
signal hit_p
var slime_scene := preload("res://cenas/slime.tscn")
var spawn_points := []
var wave_manager
@export var spawn_delay: float = 0.5

func _ready():
	print("DEBUG: _ready iniciado")
	# Aguarda um frame para que os nós fiquem disponíveis
	await get_tree().process_frame
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
			print("DEBUG: Spawn point adicionado: ", child.name, " - Posição: ", child.global_position)
	if spawn_points.size() == 0:
		print("DEBUG: Nenhum spawn point encontrado!")
	else:
		print("DEBUG: Total de spawn points: ", spawn_points.size())
	
	# Obtém o WaveManager a partir do nó principal "cenario"
	wave_manager = main.get_node("enemySpawner/WaveManager")
	if wave_manager:
		wave_manager.spawner = self
		print("DEBUG: WaveManager encontrado e atribuído")
	else:
		print("DEBUG: WaveManager não encontrado em 'cenario/enemySpawner/WaveManager'!")

func spawn_enemies(num_enemies: int, health_multiplier: float, damage_multiplier: float) -> void:
	print("DEBUG: Iniciando spawn de ", num_enemies, " inimigos")
	if spawn_points.size() == 0:
		print("DEBUG: Nenhum spawn point para spawnar inimigos!")
		return
	
	var total_spawned: int = 0
	while total_spawned < num_enemies:
		print("DEBUG: Loop spawn, total_spawned = ", total_spawned)
		var spawn_point = get_random_spawn_point()
		print("DEBUG: Spawn point selecionado: ", spawn_point.name, " - Posição: ", spawn_point.global_position)
		var success = await spawn_enemy_at(spawn_point, health_multiplier, damage_multiplier)
		if success:
			total_spawned += 1
			print("DEBUG: Inimigo spawnado com sucesso. Total agora: ", total_spawned)
			# Exibe quantos slimes estão na cena (grupo "enemies")
			print("DEBUG: Total de slimes na cena: ", get_tree().get_nodes_in_group("enemies").size())
		else:
			print("DEBUG: Falha ao spawnar inimigo no spawn point: ", spawn_point.name)
		await get_tree().create_timer(spawn_delay).timeout
	
	if wave_manager:
		wave_manager.enemies_alive = total_spawned
	print("DEBUG: Spawn finalizado. Total spawnados: ", total_spawned)

func get_random_spawn_point() -> Marker2D:
	var index = randi() % spawn_points.size()
	print("DEBUG: get_random_spawn_point - índice selecionado: ", index)
	return spawn_points[index]

func spawn_enemy_at(spawn: Marker2D, health_multiplier: float, damage_multiplier: float) -> bool:
	if spawn == null:
		print("DEBUG: Spawn point é nulo!")
		return false
	
	var slime = slime_scene.instantiate()
	if slime == null:
		print("DEBUG: Falha ao instanciar o slime!")
		return false
	
	slime.name = "Slime_" + str(randi() % 1000)
	# Adiciona um pequeno offset aleatório para evitar sobreposição exata
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	slime.position = spawn.global_position + offset
	print("DEBUG: Instanciado slime ", slime.name, " na posição: ", slime.position)
	
	# Ajusta os valores de saúde e dano, se disponíveis
	if slime.has_variable("health"):
		slime.health *= health_multiplier
		print("DEBUG: Ajustado health para ", slime.health)
	if slime.has_variable("damage"):
		slime.damage *= damage_multiplier
		print("DEBUG: Ajustado damage para ", slime.damage)
	
	main.add_child(slime)
	print("DEBUG: Slime ", slime.name, " adicionado ao nó main")
	# Aguarda um frame para confirmar que o slime entrou na árvore
	await get_tree().process_frame
	if not slime.is_inside_tree():
		print("DEBUG: Slime ", slime.name, " não entrou na árvore de cena!")
		return false
	
	slime.add_to_group("enemies")
	print("DEBUG: Slime ", slime.name, " adicionado ao grupo 'enemies'")
	if wave_manager:
		slime.connect("enemy_died", Callable(wave_manager, "enemy_died"))
		print("DEBUG: Conectado sinal enemy_died para ", slime.name)
	else:
		print("DEBUG: WaveManager não definido para conectar o sinal enemy_died!")
	
	if slime.has_method("verify_lifespan"):
		slime.call_deferred("verify_lifespan")
		print("DEBUG: Chamado verify_lifespan para ", slime.name)
	else:
		print("DEBUG: Slime ", slime.name, " não possui o método verify_lifespan")
	
	# Alterna o CollisionShape2D para forçar o update, se existir
	if slime.has_node("CollisionShape2D"):
		var collision = slime.get_node("CollisionShape2D")
		if collision:
			print("DEBUG: Encontrado CollisionShape2D em ", slime.name)
			collision.set_deferred("disabled", true)
			await get_tree().process_frame
			collision.set_deferred("disabled", false)
			print("DEBUG: CollisionShape2D reativado para ", slime.name)
		else:
			print("DEBUG: CollisionShape2D não encontrado em ", slime.name)
	
	print("DEBUG: Slime ", slime.name, " spawnado em ", spawn.global_position)
	return true
