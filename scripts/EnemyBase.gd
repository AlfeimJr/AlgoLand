extends CharacterBody2D

class_name EnemyBase

# -----------------------------
# CONFIGURAÇÕES DE MOVIMENTO
# -----------------------------
@export var speed: int = 30
@export var charge_speed: int = 100
@export var patrol_speed: int = 20
@export var separation_range: float = 50.0
@export var separation_force: float = 20.0
var direction: Vector2 = Vector2.ZERO
var last_horizontal_direction: float = 1.0  # 1 para direita, -1 para esquerda

# -----------------------------
# CONFIGURAÇÕES DE ATAQUE
# -----------------------------
@export var attack_cooldown: float = 1.5
var can_attack: bool = true
var damage: float = 1

# -----------------------------
# VARIÁVEIS DE VIDA
# -----------------------------
@export var health: int = 25
var is_dead: bool = false

# -----------------------------
# ESTADOS
# -----------------------------
var is_chasing: bool = false
var is_charging: bool = false
var is_recoiling: bool = false
var attack_cancelled: bool = false
var is_damaged: bool = false
var is_patrolling: bool = true
var patrol_direction: Vector2 = Vector2.RIGHT
var patrol_timer: float = 0.0
@export var patrol_duration: float = 2.0
@export var min_distance: float = 10.0
@export var charge_distance: float = 40.0

# -----------------------------
# NÓS DE ANIMAÇÃO E COLISÃO
# -----------------------------
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var blend_position = animation_tree.get("parameters/run/blend_position")
@onready var sprite = $Texture  # Nó do sprite para efeito de piscar

signal hit_player
signal enemy_died

func _ready() -> void:
	if animation_tree:
		animation_tree.active = true
		_set_animation("run")  # Estado inicial padrão
	
	$Area2D.monitoring = true
	$Area2D.monitorable = true
	$Area2D.set_collision_mask_value(2, true)

	# Conecta os sinais do Area2D se ainda não estiverem conectados
	if not $Area2D.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		$Area2D.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	
	if not $Area2D.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		$Area2D.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))

func _physics_process(delta: float) -> void:
	if is_dead or not has_method("_get_player"):
		return
	
	var base_velocity = Vector2.ZERO

	# Se estiver recuando (knockback)
	if is_recoiling:
		move_and_slide()
		return

	# MODO PATRULHA
	if is_patrolling:
		patrol_timer += delta
		if patrol_timer >= patrol_duration:
			patrol_timer = 0.0
			patrol_direction = -patrol_direction
		_set_animation_direction(patrol_direction)
		base_velocity = patrol_direction * patrol_speed + compute_separation()

	# PERSEGUIÇÃO
	elif is_chasing:
		var player = _get_player()
		if player:
			var distance_to_player = position.distance_to(player.position)
			if distance_to_player > min_distance:
				direction = (player.position - position).normalized()
				_set_animation_direction(direction)
			else:
				direction = Vector2.ZERO
				base_velocity = Vector2.ZERO
			if distance_to_player < charge_distance and can_attack and not is_damaged:
				charge_attack()
				return
			base_velocity = direction * speed
	else:
		base_velocity = Vector2.ZERO
		_set_animation_direction(Vector2(last_horizontal_direction, 0))  # Mantém a última direção horizontal

	velocity = base_velocity
	move_and_slide()

func compute_separation() -> Vector2:
	var repel_vector = Vector2.ZERO
	var neighbor_count = 0
	for other in get_tree().get_nodes_in_group("enemy"):
		if other != self:
			var dist = position.distance_to(other.position)
			if dist < separation_range:
				var diff = (position - other.position).normalized()
				repel_vector += diff / dist
				neighbor_count += 1
	if neighbor_count > 0:
		repel_vector /= float(neighbor_count)
		repel_vector *= separation_force
	return repel_vector

func charge_attack() -> void:
	if is_charging or not can_attack or is_damaged:
		return
	attack_cancelled = false
	can_attack = false
	is_charging = true
	_set_animation_direction(direction)
	await get_tree().create_timer(0.3).timeout
	if attack_cancelled:
		_cancel_attack()
		return
	velocity = direction * charge_speed
	move_and_slide()
	if attack_cancelled:
		_cancel_attack()
		return
	is_charging = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _cancel_attack() -> void:
	is_charging = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(damage: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	health -= damage
	if health <= 0:
		die()
		return
	_set_animation("run")
	if knockback_force == Vector2.ZERO:
		knockback_force = (position - _get_player().position).normalized() * 300.0
	is_recoiling = true
	velocity = knockback_force
	move_and_slide()
	await get_tree().create_timer(0.3).timeout
	is_recoiling = false
	velocity = Vector2.ZERO
	_blink_damage()
	await get_tree().create_timer(0.5).timeout
	_set_animation("run")

func _blink_damage() -> void:
	for i in range(5):
		sprite.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func die() -> void:
	if is_dead:
		return
	is_dead = true
	_set_animation("dead")
	await get_tree().create_timer(0.2).timeout
	emit_signal("enemy_died")
	queue_free()

func _set_animation(anim_name: String) -> void:
	if not animation_tree or not animation_state:
		return
	if animation_state.get_current_node() == anim_name:
		return
	animation_state.travel(anim_name)

func _set_animation_direction(dir: Vector2) -> void:
	if not animation_tree:
		return
	if dir.x < 0:
		last_horizontal_direction = -1.0
	elif dir.x > 0:
		last_horizontal_direction = 1.0
	blend_position.x = last_horizontal_direction
	blend_position.y = 0
	animation_tree.set("parameters/run/blend_position", blend_position)

func set_detection_scale(scale: float) -> void:
	var detection_area = get_node_or_null("Area2D")
	if detection_area:
		var collision = detection_area.get_node_or_null("CollisionShape2D")
		if collision and collision.shape is RectangleShape2D:
			var rect = collision.shape as RectangleShape2D
			rect.extents *= scale
			collision.shape = rect

func get_damage() -> int:
	return damage

# Deve ser implementado nos filhos (Ex: Slime.gd)
func _get_player() -> Node2D:
	return null

# -----------------------------
# DETECÇÃO DO JOGADOR
# -----------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == _get_player():
		is_chasing = true
		is_patrolling = false
		hit_player.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == _get_player():
		is_chasing = false
		is_patrolling = true
		patrol_timer = 0.0
		patrol_direction = Vector2.RIGHT
