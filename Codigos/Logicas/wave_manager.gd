extends Node

signal wave_started(wave: int)
signal wave_completed(wave: int)
signal game_won()
signal waves_stopped_signal

@export var starting_wave: int = 30
@export var max_enemies: int = 5	
@export var wave_interval: float = 15.0
@export var max_waves: int = 1000
@export var detection_increase_per_wave: float = 0.2
@export var gold_base_reward: int = 100
@onready var merchant = $"../../Merchant"
const MAX_ACTIVE_ENEMIES: int = 70
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
	# Define o total de inimigos para a wave no início
	enemies_alive = int(max_enemies * pow(1.5, current_wave - 1))
	# Não sobrescreva a contagem no spawner!
	enemy_health_multiplier = 1.0 + (current_wave * 0.2)
	enemy_damage_multiplier = 1.0 + (current_wave * 0.1)
	var detection_scale = 1.0 + (current_wave - 1) * detection_increase_per_wave
	var wave_banner = get_tree().get_root().get_node("cenario/UI/wave")
	if wave_banner:
		wave_banner.show_wave_number(current_wave)
	update_ui()
	# Chama o spawner para criar os inimigos
	spawner.spawn_enemies(enemies_alive, enemy_health_multiplier, enemy_damage_multiplier)

func update_ui() -> void:
	var ui = get_tree().get_root().get_node("cenario/UI")
	if ui:
		ui.enemies_label.text = "Enemies: " + str(enemies_alive)

func enemy_died() -> void:
	enemies_alive -= 1
	update_ui()
	if enemies_alive <= 0:
		var reward = gold_base_reward * current_wave
		DadosJogo.add_coins(reward)
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
