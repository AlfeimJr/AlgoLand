extends "EnemyBase.gd"
class_name SlimeSlippery
var is_currently_attacking = false
@onready var player = get_node("/root/cenario/Player")

func _ready() -> void:
	# Chama o _ready() do pai (EnemyBase)
	super()
	# Ativa a AnimationTree se houver e define o estado "run"
	if animation_tree:
		animation_tree.active = true
		_set_animation("run")
	# Configura a área de ATAQUE
	if $area_attack:
		$area_attack.monitoring = true
		$area_attack.monitorable = true
		$area_attack.set_collision_mask_value(1, true)
		
		if not $area_attack.is_connected("body_entered", Callable(self, "_on_attack_area_body_entered")):
			$area_attack.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
		if not $area_attack.is_connected("body_exited", Callable(self, "_on_attack_area_body_exited")):
			$area_attack.connect("body_exited", Callable(self, "_on_attack_area_body_exited"))
		
		# Desabilita inicialmente a hitbox de ataque
		if $area_attack.has_node("attack_collision"):
			var attack_collision = $area_attack.get_node("attack_collision")
			attack_collision.disabled = true
			print("[SlimeSlippery] attack_collision desabilitado inicialmente.")
	else:
		print("[SlimeSlippery] NÓ area_attack NÃO ENCONTRADO!")
		
	# Configura a área de dano ao player
	if $attack:
		$attack.monitoring = true
		$attack.monitorable = true
		$attack.set_collision_mask_value(1, true)
		
		if not $attack.is_connected("body_entered", Callable(self, "_on_attack_collision_player_body_entered")):
			$attack.connect("body_entered", Callable(self, "_on_attack_collision_player_body_entered"))
		
		# Desabilita inicialmente a hitbox de dano
		if $attack.has_node("attack_collision_player"):
			var attack_collision_player = $attack.get_node("attack_collision_player")
			attack_collision_player.disabled = true
			print("[SlimeSlippery] attack_collision_player desabilitado inicialmente.")
	else:
		print("[SlimeSlippery] NÓ attack NÃO ENCONTRADO!")

func _physics_process(delta: float) -> void:
	# Não chama super() para evitar a lógica da classe base que impede movimento durante ataque
	
	if is_dead or not has_method("_get_player"):
		return
	
	var base_velocity = Vector2.ZERO

	# Se estiver recuando (knockback)
	if is_recoiling:
		print("[SlimeSlippery] is_recoiling == true, executando move_and_slide() e retornando.")
		move_and_slide()
		return

	# MODO PATRULHA
	if is_patrolling:
		patrol_timer += delta
		if patrol_timer >= patrol_duration:
			patrol_timer = 0.0
			patrol_direction = -patrol_direction
			print("[SlimeSlippery] Invertendo patrulha, novo patrol_direction =", patrol_direction)
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

			if distance_to_player < attack_range and can_attack and not is_damaged:
				print("[SlimeSlippery] Player muito perto (d <", attack_range, "). Attack animado deverá ser disparado via area_attack.")
			base_velocity = direction * speed
	else:
		base_velocity = Vector2.ZERO
		_set_animation_direction(Vector2(last_horizontal_direction, 0))

	velocity = base_velocity
	move_and_slide()

# --------------------------------------------------
#  SINAIS DA ÁREA DE DETECÇÃO (PERSEGUIÇÃO)
# --------------------------------------------------
func _on_detection_area_body_entered(body: Node) -> void:
	print("[SlimeSlippery] _on_detection_area_body_entered com:", body)
	if body == player:
		print("[SlimeSlippery] É o player! is_chasing = true, is_patrolling = false")
		is_chasing = true
		is_patrolling = false

func _on_detection_area_body_exited(body: Node) -> void:
	print("[SlimeSlippery] _on_detection_area_body_exited com:", body)
	if body == player:
		print("[SlimeSlippery] Player saiu da DetectionArea. is_chasing = false, is_patrolling = true")
		is_chasing = false
		is_patrolling = true
		patrol_timer = 0.0
		patrol_direction = Vector2.RIGHT

# --------------------------------------------------
#  SINAIS DA ÁREA DE ATAQUE
# --------------------------------------------------
func _on_attack_area_body_entered(body: Node) -> void:
	print("[SlimeSlippery] _on_attack_area_body_entered com:", body)
	if body == player:
		print("[SlimeSlippery] É o player! can_attack:", can_attack, " is_dead:", is_dead)
		in_attack_area = true
		is_chasing = true
		is_patrolling = false
		if can_attack and not is_dead:
			print("[SlimeSlippery] Chamando _attack_player()...")
			_attack_player()

func _on_attack_area_body_exited(body: Node) -> void:
	print("[SlimeSlippery] _on_attack_area_body_exited com:", body)
	if body == player:
		in_attack_area = false
		print("[SlimeSlippery] Player saiu da área de ataque.")

# Função para quando o player entra na área de colisão que dá dano
# Função para quando o player entra na área de colisão que dá dano
func _on_attack_collision_player_body_entered(body: Node) -> void:
	if body == player:
		print("[SlimeSlippery] Player atingido pelo ataque!")
		# Aplica dano ao player
		if body.has_method("take_damage"):
			# Calcula a direção do knockback (do inimigo para o player)
			var knockback_direction = (player.position - position).normalized()
			# Define a força do knockback
			var knockback_force = knockback_direction * 150.0
			
			# Aplica dano com o knockback
			body.take_damage(get_damage(), knockback_force)
			emit_signal("hit_player")

# --------------------------------------------------
#  LÓGICA DE ATAQUE (usando estado único "attack" com blend)
# --------------------------------------------------
func _attack_player() -> void:
	if is_currently_attacking:
		return
		
	is_currently_attacking = true
	print("[SlimeSlippery] >> _attack_player chamado!")
	is_attacking = true
	can_attack = false
	
	# Calcula o vetor em direção ao player
	var dir_to_player = player.position - position
	print("[SlimeSlippery] dir_to_player =", dir_to_player)
	
	# Viaja para o estado "attack" no AnimationTree
	_set_animation("attack")
	
	# Ajusta o blend para definir a direção do ataque
	var blend_vec = Vector2.ZERO
	if abs(dir_to_player.x) > abs(dir_to_player.y):
		blend_vec.x = sign(dir_to_player.x)  # +1 para direita, -1 para esquerda
	else:
		blend_vec.y = sign(dir_to_player.y)  # +1 para baixo, -1 para cima
	
	print("[SlimeSlippery] Ajustando blend_position para:", blend_vec)
	animation_tree.set("parameters/attack/blend_position", blend_vec)
	
	# Ativa a hitbox de dano no momento certo da animação
	await get_tree().create_timer(0.1).timeout
	
	# Ativa a hitbox de dano (attack_collision_player)
	if $attack and $attack.has_node("attack_collision_player"):
		print("[SlimeSlippery] Habilitando attack_collision_player.")
		var attack_collision_player = $attack.get_node("attack_collision_player")
		attack_collision_player.disabled = false
	
	# Aguarda a duração da animação de ataque
	await get_tree().create_timer(0.2).timeout
	
	# Desativa a hitbox de dano
	if $attack and $attack.has_node("attack_collision_player"):
		print("[SlimeSlippery] Desabilitando attack_collision_player.")
		var attack_collision_player = $attack.get_node("attack_collision_player")
		attack_collision_player.disabled = true
	
	# Muda para a animação de run após o ataque
	_set_animation("run")
	
	# Aguarda o cooldown de 2 segundos
	print("[SlimeSlippery] Esperando cooldown de 2 segundos.")
	await get_tree().create_timer(2.0).timeout
	
	# Libera o ataque após o cooldown
	print("[SlimeSlippery] Liberando can_attack = true.")
	can_attack = true
	is_attacking = false
	is_currently_attacking = false

# Exemplo de método específico do Slime
func slime_special_behavior():
	print("[SlimeSlippery] Executando comportamento especial do slime!")

func _get_player() -> Node2D:
	return player
