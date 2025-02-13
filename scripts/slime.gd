extends CharacterBody2D
class_name Slime

@onready var player = get_node("/root/cenario/baseCharacter")
signal hit_player
signal enemy_died  # Sinal para notificar a morte

# -----------------------------
# CONFIGURAÇÕES DE MOVIMENTO
# -----------------------------
@export var speed: int = 30
@export var charge_speed: int = 100
@export var patrol_speed: int = 20

# Parâmetros de separação
@export var separation_range: float = 50.0
@export var separation_force: float = 20.0

# Variáveis de direção
var direction: Vector2 = Vector2.ZERO

# -----------------------------
# CONFIGURAÇÕES DE ATAQUE
# -----------------------------
@export var attack_cooldown: float = 1.5
var can_attack: bool = true
var damage: int = 1

# -----------------------------
# VARIÁVEIS DE VIDA
# -----------------------------
var health: int = 3
var is_dead: bool = false

# -----------------------------
# ESTADOS
# -----------------------------
var is_chasing: bool = false
var is_charging: bool = false
var is_recoiling: bool = false

var attack_cancelled: bool = false
var is_damaged: bool = false

# Estado de patrulha (quando o player não está na área)
var is_patrolling: bool = true  # Ao nascer, já inicia em patrulha
var patrol_direction: Vector2 = Vector2.RIGHT
var patrol_timer: float = 0.0
var patrol_duration: float = 2.0  # Tempo para trocar de direção

# -----------------------------
# PARÂMETROS DE DISTÂNCIA
# -----------------------------
var min_distance: float = 10.0
var charge_distance: float = 40.0

func _ready() -> void:
	if player == null:
		print("ERRO: Jogador não encontrado!")
		return

	# Inicia em modo patrulha
	is_patrolling = true
	is_chasing = false

	# Configure o Area2D para monitoramento sem colisão física
	$Area2D.monitoring = true
	$Area2D.monitorable = true
	# Ajusta a máscara para detectar o jogador na layer 2 (ajuste conforme necessário)
	$Area2D.set_collision_mask_value(2, true)

	# Conecta os sinais de detecção, se não estiverem conectados
	if not $Area2D.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		$Area2D.body_entered.connect(_on_area_2d_body_entered)
	if not $Area2D.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		$Area2D.body_exited.connect(_on_area_2d_body_exited)

func _physics_process(delta: float) -> void:
	if is_dead or player == null:
		return
	
	var base_velocity = Vector2.ZERO
	
	# Se estiver recuando, mantém a velocity atual e sai
	if is_recoiling:
		base_velocity = velocity
		velocity = base_velocity
		move_and_slide()
		return
	
	# MODO PATRULHA: quando o player NÃO está na área
	if is_patrolling:
		# Toca a animação de patrulha ("run" ou "guard", conforme preferir)
		$AnimatedSprite2D.play("run")
		patrol_timer += delta
		if patrol_timer >= patrol_duration:
			patrol_timer = 0.0
			patrol_direction = -patrol_direction
			$AnimatedSprite2D.flip_h = patrol_direction.x < 0
		# Aplica a velocidade de patrulha e soma a força de separação
		base_velocity = patrol_direction * patrol_speed + compute_separation()
	
	# PERSEGUIÇÃO e ATAQUE
	elif is_chasing:
		$AnimatedSprite2D.play("run")
		var distance_to_player = position.distance_to(player.position)
		if distance_to_player > min_distance:
			direction = (player.position - position).normalized()
		else:
			direction = Vector2.ZERO
			base_velocity = Vector2.ZERO
		# Se estiver dentro do charge_distance e puder atacar, inicia o ataque
		if distance_to_player < charge_distance and can_attack and not is_damaged:
			charge_attack()
			return
		$AnimatedSprite2D.flip_h = direction.x < 0
		base_velocity = direction * speed
	
	else:
		base_velocity = Vector2.ZERO
	
	velocity = base_velocity
	move_and_slide()

#
# -----------------------------------------
# FUNÇÃO DE SEPARAÇÃO (Repulsão)
# -----------------------------------------
func compute_separation() -> Vector2:
	var repel_vector = Vector2.ZERO
	var neighbor_count = 0
	for other in get_tree().get_nodes_in_group("enemies"):
		if other != self:
			var dist = position.distance_to(other.position)
			if dist < separation_range:
				var diff = (position - other.position).normalized()
				# Quanto mais perto, mais forte a repulsão
				repel_vector += diff / dist
				neighbor_count += 1
	if neighbor_count > 0:
		repel_vector /= float(neighbor_count)
		repel_vector *= separation_force
	return repel_vector

#
# -----------------------------------------
# SINAIS DO AREA2D
# -----------------------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		print("Jogador detectado! Iniciando perseguição...")
		is_chasing = true
		is_patrolling = false
		hit_player.emit()
	else:
		print("body_entered:", body.name)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		print("Jogador saiu da área! Iniciando patrulha...")
		is_chasing = false
		is_patrolling = true
		patrol_timer = 0.0
		patrol_direction = Vector2.RIGHT
		$AnimatedSprite2D.flip_h = false

#
# -----------------------------------------
# ATAQUE (CHARGE)
# -----------------------------------------
func charge_attack() -> void:
	if is_charging or not can_attack or is_damaged:
		return
	
	attack_cancelled = false
	can_attack = false
	print("Slime avançando!")
	is_charging = true
	$AnimatedSprite2D.play("run")
	
	await get_tree().create_timer(0.3).timeout
	if attack_cancelled:
		_cancel_attack()
		return
	
	velocity = direction * charge_speed
	move_and_slide()
	if attack_cancelled:
		_cancel_attack()
		return
	
	if position.distance_to(player.position) < charge_distance:
		var knockback_dir = (player.position - position).normalized()
		player.apply_knockback(knockback_dir * 300.0)
		is_recoiling = true
		velocity = -knockback_dir * (charge_speed * 0.5)
		move_and_slide()
		await get_tree().create_timer(0.3).timeout
		is_recoiling = false
	
	is_charging = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _cancel_attack() -> void:
	print("Ataque cancelado! Slime recuando...")
	is_charging = false
	velocity = Vector2.ZERO
	var recoil_dir = (position - player.position).normalized()
	is_recoiling = true
	velocity = recoil_dir * (charge_speed * 0.5)
	move_and_slide()
	await get_tree().create_timer(0.3).timeout
	is_recoiling = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

#
# -----------------------------------------
# DANO E MORTE
# -----------------------------------------
func take_damage(damage: int, _knockback_force: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	
	is_damaged = true
	health -= damage
	print("Slime recebeu dano! Vida restante:", health)
	if health <= 0:
		die()
		return
	
	if is_charging:
		attack_cancelled = true
	
	_blink_damage()
	
	if _knockback_force != Vector2.ZERO:
		is_recoiling = true
		velocity = _knockback_force
		move_and_slide()
		await get_tree().create_timer(0.3).timeout
		is_recoiling = false
		velocity = Vector2.ZERO
	
	if health <= 0:
		die()
		return
	
	# Após receber dano, retoma a perseguição
	is_chasing = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("run")
	is_damaged = false

func _blink_damage() -> void:
	$AnimatedSprite2D.play("damaged")
	for i in range(5):
		$AnimatedSprite2D.modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	print("Slime morreu!")
	$Area2D.set_deferred("monitoring", false)
	$Area2D.set_deferred("monitorable", false)
	$Area2D.get_node("CollisionShape2D").set_deferred("disabled", true)
	is_chasing = false
	is_patrolling = false
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("dead")
	emit_signal("enemy_died")
	print("Aguardando fim da animação...")
	await $AnimatedSprite2D.animation_finished
	print("Removendo Slime da cena...")
	queue_free()
