extends CharacterBody2D

class_name Slime

@onready var player = get_node("/root/cenario/baseCharacter")
signal hit_player
signal enemy_died  # <- Adicione esse sinal no Slime
# Variáveis de controle de movimento
var speed: int = 30
var charge_speed: int = 100  # Velocidade do avanço
var direction: Vector2 = Vector2.ZERO
var attack_cooldown: float = 1.5  # Tempo de espera entre os ataques
var can_attack: bool = true       # Indica se o slime pode atacar
var damage: int = 1 
# Variáveis de vida e controle de morte
var health: int = 3
var is_dead: bool = false
var twen

# Indica se o slime está perseguindo o jogador
var is_chasing: bool = false
var is_charging: bool = false  # Está avançando
var is_recoiling: bool = false # Está recuando

# Flag para cancelar o ataque (quando o player ataca no meio do avanço)
var attack_cancelled: bool = false

# Flag para indicar que o slime está no estado de dano (pisca, etc)
var is_damaged: bool = false

# Distância mínima para evitar ficar colado no jogador
var min_distance: float = 10.0
var charge_distance: float = 40.0  # Distância para iniciar o avanço

func _ready() -> void:
	if player == null:
		print("ERRO: Jogador não encontrado!")
		return

	$Area2D.set_collision_layer_value(1, false)  # Remove colisão física
	$Area2D.set_collision_mask_value(2, true)      # Só detecta o jogador no layer 2

	# Conectar sinais, se ainda não estiverem conectados
	if not $Area2D.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		$Area2D.body_entered.connect(_on_area_2d_body_entered)
	if not $Area2D.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		$Area2D.body_exited.connect(_on_area_2d_body_exited)

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		return  # Não mover se morto ou sem referência

	# Se estiver recuando (por dano ou cancelamento de ataque), não sobrescreve a velocidade
	if is_recoiling:
		move_and_slide()
		return

	$AnimatedSprite2D.animation = "run"

	if is_charging:
		# Se não estiver recuando, avança normalmente
		if not is_recoiling:
			velocity = direction * charge_speed
		move_and_slide()
		return

	if is_chasing:
		var distance_to_player = position.distance_to(player.position)
		if distance_to_player > min_distance:
			direction = (player.position - position).normalized()
		else:
			direction = Vector2.ZERO
			velocity = Vector2.ZERO
			return

		# Impede o ataque se o slime estiver no estado de dano
		if distance_to_player < charge_distance and can_attack and not is_damaged:
			charge_attack()
			return

		$AnimatedSprite2D.flip_h = direction.x < 0
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "baseCharacter":
		print("Jogador detectado! Iniciando perseguição...")
		is_chasing = true
		hit_player.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "baseCharacter":
		print("Jogador saiu da área! Parando perseguição...")
		is_chasing = false

func charge_attack() -> void:
	# Não executa ataque se já estiver atacando, não puder atacar ou estiver danificado
	if is_charging or not can_attack or is_damaged:
		return

	attack_cancelled = false  # Reseta a flag
	can_attack = false        # Bloqueia novos ataques durante o cooldown
	print("Slime avançando!")
	is_charging = true
	$AnimatedSprite2D.animation = "run"
	
	# Pequena pausa antes do avanço (opcional)
	await get_tree().create_timer(0.3).timeout
	if attack_cancelled:
		_cancel_attack()
		return
	
	# Avança em direção ao jogador
	velocity = direction * charge_speed
	move_and_slide()
	if attack_cancelled:
		_cancel_attack()
		return
	
	# Se estiver perto o suficiente, aplica knockback no player e recua
	if position.distance_to(player.position) < charge_distance:
		var knockback_dir = (player.position - position).normalized()
		player.apply_knockback(knockback_dir * 300.0)
		is_recoiling = true
		velocity = -knockback_dir * (charge_speed * 0.5)
		move_and_slide()
		await get_tree().create_timer(0.3).timeout
		is_recoiling = false
	
	# Finaliza o ataque
	is_charging = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# Função auxiliar para cancelar o ataque e recuar
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

func take_damage(damage: int, _knockback_force: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return  # 🔥 Se já estiver morto, ignora qualquer dano extra

	is_damaged = true
	health -= damage
	print("Slime recebeu dano! Vida restante:", health)

	if health <= 0:
		die()  # 🔥 Chama a morte, mas apenas se ele não tiver morrido antes
		return
	
	health -= damage
	print("Slime recebeu dano! Vida restante:", health)
	
	# Se estiver atacando, cancela o ataque
	if is_charging:
		attack_cancelled = true

	# Inicia o piscar imediatamente (sem await para rodar em paralelo)
	_blink_damage()

	# Se for recebido um knockback pelo player, aplica-o
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

	# Opcional: desativa temporariamente a perseguição enquanto exibe o dano
	is_chasing = false
	velocity = Vector2.ZERO
	$AnimatedSprite2D.animation = "run"
	is_chasing = true

	# Ao final do efeito de dano, libera o ataque
	is_damaged = false

# Função assíncrona para piscar (efeito de dano)
func _blink_damage() -> void:
	$AnimatedSprite2D.animation = "damaged"
	$AnimatedSprite2D.play()
	# Pisca 5 vezes
	for i in range(5):
		$AnimatedSprite2D.modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func die() -> void:
	if is_dead:  # Se já estiver morto, não executa de novo
		return

	is_dead = true  # 🔥 Marca o Slime como morto para evitar execução dupla
	print("Slime morreu!")

	$Area2D.set_deferred("monitoring", false)
	$Area2D.set_deferred("monitorable", false)
	$Area2D.get_node("CollisionShape2D").set_deferred("disabled", true)

	is_chasing = false
	velocity = Vector2.ZERO

	$AnimatedSprite2D.animation = "dead"
	$AnimatedSprite2D.play()

	# 🔥 Emite o sinal APENAS UMA VEZ
	emit_signal("enemy_died")

	print("Aguardando fim da animação...")
	await $AnimatedSprite2D.animation_finished
	print("Removendo Slime da cena...")
	queue_free()
