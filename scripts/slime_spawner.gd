extends Node2D

@onready var main = get_node("/root/cenario")

signal hit_p
var slime_scene := preload("res://slime.tscn")
var spawn_points := []
var wave_manager
@export var spawn_delay: float = 0.5  # 🕒 Delay entre os spawns (meio segundo)

# Índice para iterar cíclicamente pelos spawn points
var current_spawn_index: int = 0

func _ready():
	await get_tree().process_frame  # Aguarda um frame para garantir que tudo carregou
	
	# Captura os pontos de spawn (Marker2D filhos desta cena)
	for child in get_children():
		if child is Marker2D:
			print("📌 Ponto de Spawn:", child.position)
			spawn_points.append(child)
	
	if spawn_points.size() > 0:
		print("✅ Spawner pronto com", spawn_points.size(), "pontos de spawn.")
	else:
		print("❌ Nenhum spawn point encontrado! Verifique a cena.")
	
	# Obtém referência ao WaveManager
	wave_manager = get_parent().get_node("/root/cenario/enemySpawner/WaveManager")
	wave_manager.spawner = self  # Garante que ambos compartilhem os mesmos spawn points

func spawn_enemies(num_enemies: int, health_multiplier: float, damage_multiplier: float) -> void:
	print("🔎 Tentando spawnar", num_enemies, "inimigos.")
	
	if spawn_points.is_empty():
		print("⚠️ ERRO: Nenhum ponto de spawn disponível!")
		return
	
	var total_spawned: int = 0
	
	# Loop para spawnar todos os inimigos desejados usando os pontos de spawn de forma cíclica
	while total_spawned < num_enemies:
		var spawn_point = get_next_spawn_point()
		var success = await spawn_enemy_at(spawn_point, health_multiplier, damage_multiplier)
		if success:
			total_spawned += 1
		else:
			print("⚠️ Falha ao spawnar inimigo", total_spawned + 1)
		
		# Delay entre os spawns para evitar sobrecarga na engine
		await get_tree().create_timer(spawn_delay).timeout
	
	# Atualiza a contagem de inimigos vivos no WaveManager
	wave_manager.enemies_alive = total_spawned
	print("✅ Total de inimigos spawnados:", total_spawned)

# Retorna o próximo spawn point de forma cíclica
func get_next_spawn_point() -> Marker2D:
	if spawn_points.is_empty():
		return null
	var spawn = spawn_points[current_spawn_index]
	current_spawn_index = (current_spawn_index + 1) % spawn_points.size()
	return spawn

func spawn_enemy_at(spawn: Marker2D, health_multiplier: float, damage_multiplier: float) -> bool:
	if spawn == null:
		print("⚠️ ERRO: Spawn inválido!")
		return false
	
	var slime = slime_scene.instantiate()
	if slime == null:
		print("❌ ERRO: Falha ao instanciar Slime!")
		return false
	
	# Garante um nome único para debugging
	slime.name = "Slime_" + str(randi() % 1000)
	slime.position = spawn.position
	slime.health *= health_multiplier
	slime.damage *= damage_multiplier
	
	main.add_child(slime)
	
	# Aguarda um frame para garantir que o slime foi adicionado à árvore
	await get_tree().process_frame
	if not slime.is_inside_tree():
		print("❌ ERRO: Slime não foi adicionado à árvore corretamente!")
		return false
	
	slime.add_to_group("enemies")
	slime.connect("enemy_died", Callable(wave_manager, "enemy_died"))
	
	print("🐍 Slime spawnado com sucesso:", slime.name, "na posição:", slime.position)
	
	# Chama de forma adiada o método de verificação de vida do Slime
	slime.call_deferred("verify_lifespan")
	
	# Desativa a colisão temporariamente para evitar problemas de física
	var collision = slime.get_node("CollisionShape2D")
	if collision:
		print("🔴 Desativando colisão do Slime antes do spawn")
		collision.set_deferred("disabled", true)
		await get_tree().process_frame  # Aguarda um frame para evitar bugs de física
		collision.set_deferred("disabled", false)
		print("🟢 Colisão reativada para o Slime:", slime.name)
	else:
		print("⚠️ ERRO: Slime não possui CollisionShape2D!")
	
	return true  # Indica que o Slime foi spawnado com sucesso

# Testa se o Slime permanece na cena após spawnar
func verify_lifespan() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		print("⚠️ ALERTA: Slime desapareceu inesperadamente:", name)
