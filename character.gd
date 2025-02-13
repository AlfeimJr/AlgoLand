extends CharacterBody2D

@export_category("Variables")
@export var _move_speed: float = 64.0
@export var _friction: float = 0.3
@export var _acceleration: float = 0.3
@export var _attack_damage: int = 1  # Quantidade de dano que o ataque causa
@export var _knockback_strength: float = 200.0
@export var _knockback_decay: float = 0.1

@export_category("Objects")
@export var _animation_tree: AnimationTree = null
@export var _timer: Timer = null

var _state_machine: Object
var _is_attacking: bool = false
var _knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	_state_machine = _animation_tree["parameters/playback"]
	
	# Configuração de layer/mask do AttackArea
	$AttackArea.collision_layer = 1 << 1   # Layer 2
	$AttackArea.collision_mask  = 1 << 2   # Mask 4
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false
	
	# Conecta os sinais de AttackArea, evitando duplicações
	connect_signal_if_not_connected($AttackArea, "body_entered", "_on_attack_body_entered")
	connect_signal_if_not_connected($AttackArea, "area_entered", "_on_attack_area_area_entered")

# Método auxiliar para conectar sinais evitando duplicações
func connect_signal_if_not_connected(node: Node, signal_name: String, method: String) -> void:
	if not node.is_connected(signal_name, Callable(self, method)):
		node.connect(signal_name, Callable(self, method))
		print("Sinal ", signal_name, " conectado ao método ", method)

func _physics_process(_delta: float) -> void:
	# Se houver knockback ativo, aplica-o (e vai diminuindo-o)
	if _knockback.length() > 1:
		velocity = _knockback
		_knockback = _knockback.lerp(Vector2.ZERO, _knockback_decay)  # Faz o empurrão diminuir suavemente
	else:
		_move()
		_attack()
	
	move_and_slide()
	_animate()

func apply_knockback(force: Vector2) -> void:
	_knockback = force  # Aplica o empurrão
	print("Player sofreu knockback!")

	# Faz o player piscar (efeito de dano)
	for i in range(5):  # Pisca 5 vezes
		modulate.a = 0.2  # Fica quase invisível
		await get_tree().create_timer(0.1).timeout  # Espera 0.1s
		modulate.a = 1.0  # Volta ao normal
		await get_tree().create_timer(0.1).timeout  # Espera 0.1s

func _attack() -> void:
	if Input.is_action_just_pressed("attack") and not _is_attacking:
		_is_attacking = true
		_timer.start()
		$AttackArea.monitoring = true
		$AttackArea.monitorable = true

func _move() -> void:
	var dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up",   "move_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		_animation_tree["parameters/idle/blend_position"]   = dir
		_animation_tree["parameters/walk/blend_position"]   = dir
		_animation_tree["parameters/attack/blend_position"] = dir
		velocity.x = lerp(velocity.x, dir.x * _move_speed, _acceleration)
		velocity.y = lerp(velocity.y, dir.y * _move_speed, _acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, _friction)
		velocity.y = lerp(velocity.y, 0.0, _friction)

func _animate() -> void:
	if _is_attacking:
		_state_machine.travel("attack")
		return
	if velocity.length() > 2:
		_state_machine.travel("walk")
	else:
		_state_machine.travel("idle")

func _on_attack_timer_timeout() -> void:
	_is_attacking = false
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false

func _on_attack_area_area_entered(area: Area2D) -> void:
	print("Área de ataque entrou em contato com outra área:", area.name)

func _on_attack_body_entered(body: Node2D) -> void:
	print("Colisão detectada com: ", body.name)
	if body is Slime:
		print("O corpo é um Slime!")
		if not body.is_dead:
			print("Causando dano ao Slime...")
			var knockback_dir = (body.position - position).normalized()
			body.take_damage(_attack_damage, knockback_dir * _knockback_strength)
