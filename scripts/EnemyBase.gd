extends CharacterBody2D
class_name EnemyBase

# -----------------------------
# CONFIGURAÇÕES DE MOVIMENTO
# -----------------------------
@export var speed: int = 30
@export var patrol_speed: int = 20
@export var separation_range: float = 50.0
@export var separation_force: float = 20.0
var direction: Vector2 = Vector2.ZERO
var last_horizontal_direction: float = 1.0  # 1 para direita, -1 para esquerda

# -----------------------------
# CONFIGURAÇÕES DE ATAQUE
# -----------------------------
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 20.0   # Distância mínima para que o attack animado seja priorizado
var can_attack: bool = true
var damage: float = 15

# -----------------------------
# VARIÁVEIS DE VIDA
# -----------------------------
@export var health: int = 25
var is_dead: bool = false

# -----------------------------
# ESTADOS
# -----------------------------
var is_chasing: bool = false
var is_recoiling: bool = false
var is_damaged: bool = false
var is_patrolling: bool = true
var patrol_direction: Vector2 = Vector2.RIGHT
var patrol_timer: float = 0.0
@export var patrol_duration: float = 2.0
@export var min_distance: float = 10.0

# Flag para indicar se o player está na área de ataque.
var in_attack_area: bool = false

# Flag para indicar se o inimigo está atacando.
var is_attacking: bool = false

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
	# Ativa a AnimationTree e define o estado "run"
	if animation_tree:
		animation_tree.active = true
		_set_animation("run")
	
	# Configura a área de DETECÇÃO
	if $DetectionArea:
		$DetectionArea.monitoring = true
		$DetectionArea.monitorable = true
		$DetectionArea.set_collision_mask_value(2, true)
		if not $DetectionArea.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
			$DetectionArea.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
		if not $DetectionArea.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
			$DetectionArea.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))
	
	# >>> INTEGRAÇÃO DA BARRA DE HP <<<
	# Se o nó HPBar não estiver presente, instancia e adiciona como filho do inimigo.
	if not has_node("HPBar"):
		var hp_bar_scene = preload("res://cenas/hp_bar.tscn")
		var hp_bar_instance = hp_bar_scene.instantiate()
		hp_bar_instance.name = "HPBar"
		add_child(hp_bar_instance)
		# Posiciona a barra acima do inimigo (ajuste conforme necessário)
		hp_bar_instance.position = Vector2(0, -40)

func _physics_process(delta: float) -> void:
	# Não chama super() para evitar a lógica da classe base que impede movimento durante ataque
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
			base_velocity = direction * speed
	else:
		base_velocity = Vector2.ZERO
		_set_animation_direction(Vector2(last_horizontal_direction, 0))

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

func take_damage(damage_amount: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= damage_amount

	# Exibe texto de dano flutuante
	spawn_damage_label(damage_amount)
	
	# Atualiza a barra de HP, se existir
	if has_node("HPBar"):
		get_node("HPBar").update_bar(health)

	# Verifica se o inimigo morreu
	if health <= 0:
		die()
		return

	# Se não estiver atacando, volta a animação para "run"
	if not is_attacking:
		_set_animation("run")

	# Se não foi passado knockback_force, calcula um padrão
	if knockback_force == Vector2.ZERO:
		knockback_force = (position - _get_player().position).normalized() * 300.0

	# Aplica o knockback (recuo)
	is_recoiling = true
	velocity = knockback_force
	move_and_slide()

	# Espera um pouco (0.3s) para manter o knockback
	await get_tree().create_timer(0.3).timeout
	is_recoiling = false
	velocity = Vector2.ZERO

	# Pisca para indicar dano
	_blink_damage()

	# Espera mais um pouco antes de voltar para a animação "run"
	await get_tree().create_timer(0.5).timeout
	if not is_attacking:
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
	var detection_area = get_node_or_null("DetectionArea")
	if detection_area:
		var collision = detection_area.get_node_or_null("CollisionShape2D")
		if collision and collision.shape is RectangleShape2D:
			var rect = collision.shape as RectangleShape2D
			rect.extents *= scale
			collision.shape = rect

func get_damage() -> int:
	return damage

# Para ser sobrescrito nos filhos (Ex: SlimeSlippery.gd)
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
		if not in_attack_area:
			is_chasing = false
			is_patrolling = true
			patrol_timer = 0.0
			patrol_direction = Vector2.RIGHT


# -------------------------------------------------
# FUNÇÃO PARA CRIAR O TEXTO DE DANO ACIMA DO INIMIGO
# -------------------------------------------------
func spawn_damage_label(damage_value: int) -> void:
	var label_scene = preload("res://cenas/floating_damage_label.tscn")
	var label_instance = label_scene.instantiate()

	# Posição do Node2D (a cena do texto)
	label_instance.global_position = global_position - Vector2(0, 20)

	# Chama o método 'set_damage' do script
	label_instance.set_damage(damage_value)

	# Adiciona na cena
	get_tree().current_scene.add_child(label_instance)
