extends Node

signal wave_started(wave: int)
signal wave_completed(wave: int)
signal game_won()  # Sinal para indicar vitória

@export var starting_wave: int = 1
@export var max_enemies: int = 5
@export var wave_interval: float = 15.0
@export var max_waves: int = 10

const MAX_ACTIVE_ENEMIES: int = 50

# Aqui definimos o retângulo que cobre a área verde do seu cenário
@export var green_area := Rect2(Vector2(64, 192), Vector2(800, 400))

var current_wave: int = 1
var enemies_alive: int = 0
var enemies_spawned: int = 0
var enemy_health_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var spawner

func _ready() -> void:
	await get_tree().process_frame
	
	current_wave = starting_wave
	spawner = get_tree().get_root().get_node("cenario/enemySpawner")
	if spawner:
		print("✅ Spawner encontrado:", spawner)
	else:
		print("❌ ERRO: Spawner não encontrado!")
	
	await get_tree().process_frame  
	start_wave()

func start_wave() -> void:
	if current_wave > max_waves:
		emit_signal("game_won")
		print("🏆 Todas as waves foram completadas!")
		return

	emit_signal("wave_started", current_wave)
	enemies_spawned = 0
	enemies_alive = min(max_enemies + (current_wave * 2), max_enemies * 2)
	enemy_health_multiplier = 1.0 + (current_wave * 0.2)
	enemy_damage_multiplier = 1.0 + (current_wave * 0.1)

	print("🌊 Iniciando Wave", current_wave, "- Inimigos:", enemies_alive)

	var wave_banner = get_tree().get_root().get_node("cenario/UI/wave")
	if wave_banner:
		wave_banner.show_wave_number(current_wave)

	update_ui()
	spawn_enemies(enemies_alive, enemy_health_multiplier, enemy_damage_multiplier)

func update_ui() -> void:
	var ui = get_tree().get_root().get_node("cenario/UI")
	if ui:
		ui.enemies_label.text = "Enemys: " + str(enemies_alive)

func spawn_enemies(num_enemies: int, health_multiplier: float, damage_multiplier: float) -> void:
	print("🔎 Tentando spawnar", num_enemies, "inimigos.")

	if not spawner or spawner.spawn_points.is_empty():
		print("⚠️ ERRO: Nenhum ponto de spawn disponível ou Spawner inválido!")
		return

	spawner.spawn_points.shuffle()

	for i in range(num_enemies):
		while get_tree().get_nodes_in_group("enemies").size() >= MAX_ACTIVE_ENEMIES:
			await get_tree().create_timer(0.5).timeout
		
		var spawn_position = get_valid_spawn_position()
		if spawn_position != Vector2.ZERO:
			spawn_enemy(spawn_position, health_multiplier, damage_multiplier)
		else:
			print("⚠️ Não foi possível encontrar um spawn válido para o inimigo", i + 1)
		
		await get_tree().create_timer(0.1).timeout

func get_valid_spawn_position() -> Vector2:
	# Tenta achar um spawn livre
	for spawn in spawner.spawn_points:
		var is_valid = true
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.position.distance_to(spawn.position) < 20:
				is_valid = false
				break
		if is_valid:
			return spawn.position

	# Se nenhum spawn livre for encontrado, gera um ponto aleatório dentro de green_area
	print("🔔 Nenhum spawn livre encontrado. Gerando novo spawn point dentro de green_area.")
	var new_spawn = Marker2D.new()

	var spawn_x = randf_range(green_area.position.x, green_area.position.x + green_area.size.x)
	var spawn_y = randf_range(green_area.position.y, green_area.position.y + green_area.size.y)

	new_spawn.position = Vector2(spawn_x, spawn_y)
	spawner.add_child(new_spawn)
	spawner.spawn_points.append(new_spawn)
	return new_spawn.position

func spawn_enemy(position: Vector2, health_multiplier: float, damage_multiplier: float):
	if position == Vector2.ZERO:
		print("⚠️ ERRO: Nenhuma posição válida encontrada para spawn!")
		return

	var slime = spawner.slime_scene.instantiate()
	if slime == null:
		print("❌ ERRO: Falha ao instanciar Slime!")
		return

	slime.position = position
	slime.health *= health_multiplier
	slime.damage *= damage_multiplier

	get_tree().get_root().get_node("cenario").add_child(slime)
	slime.add_to_group("enemies")
	slime.connect("enemy_died", Callable(self, "enemy_died"))

	print("🐍 Slime spawnado na posição:", slime.position)

	configure_enemy_collision(slime)

func configure_enemy_collision(enemy):
	print("🔎 Configurando colisão para:", enemy.name)
	enemy.collision_layer = 1 << 2
	enemy.collision_mask = (1 << 0) | (1 << 1)
	var collision = enemy.get_node("CollisionShape2D")
	if collision:
		print("🔴 Desativando colisão do Slime antes do spawn")
		collision.set_deferred("disabled", true)
		await get_tree().process_frame
		collision.set_deferred("disabled", false)
		print("🟢 Colisão reativada para o Slime:", enemy.name)
	else:
		print("⚠️ ERRO: Slime não possui CollisionShape2D!")

func enemy_died() -> void:
	enemies_alive -= 1
	print("💀 Inimigo morreu! Restantes:", enemies_alive)
	update_ui()

	if enemies_alive <= 0:
		print("🌊 Wave", current_wave, "completada!")
		emit_signal("wave_completed", current_wave)
		await get_tree().create_timer(wave_interval).timeout
		current_wave += 1
		start_wave()
