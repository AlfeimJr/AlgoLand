extends CharacterBody2D

# Nó do jogador (ajuste o caminho conforme necessário)
@onready var player = get_node("/root/cenario/baseCharacter")

# Variáveis de controle de movimento
var speed: int = 20  # Velocidade do slime
var direction: Vector2 = Vector2.ZERO  # Direção do movimento
var is_chasing: bool = false  # Indica se o slime está perseguindo o jogador

# Distância mínima para evitar que o slime fique preso no jogador
@export var min_distance: float = 30.0

# Variáveis de vida e controle de morte
var health: int = 3
var is_dead: bool = false

func _ready() -> void:
	# Conecta o sinal body_entered do Area2D ao método _on_area_2d_body_entered
	$Area2D.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))

func _physics_process(delta: float) -> void:
	if is_dead:
		return  # Não move o slime se ele estiver morto

	if is_chasing:
		# Calcula a direção para o jogador apenas se estiver fora da distância mínima
		var to_player = player.position - position
		if to_player.length() > min_distance:
			direction = to_player.normalized()
		else:
			direction = Vector2.ZERO  # Para o slime se estiver muito perto

		# Atualiza a orientação horizontal do sprite
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = true  # Olha para a esquerda
		elif direction.x > 0:
			$AnimatedSprite2D.flip_h = false  # Olha para a direita

		# Move o slime em direção ao jogador
		velocity = direction * speed
		move_and_slide()

		# Verifica se o slime está colidindo com o jogador
		for index in get_slide_collision_count():
			var collision = get_slide_collision(index)
			if collision.get_collider() == player:
				print("Colisão direta com o jogador!")
				is_chasing = false  # Desativa a perseguição temporariamente
				break
	else:
		velocity = Vector2.ZERO  # Para o slime se não estiver perseguindo

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Colisão detectada com:", body.name)
	if body is CharacterBody2D and body.name == "baseCharacter":
		print("Jogador detectado! Iniciando perseguição...")
		is_chasing = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	# Verifica se o corpo que saiu é o jogador
	if body is CharacterBody2D and body.name == "baseCharacter":
		print("Jogador saiu da área! Parando perseguição...")
		is_chasing = false

func take_damage(damage: int) -> void:
	if is_dead:
		print("Slime já está morto.")
		return
	health -= damage
	print("Slime recebeu dano! Vida restante: ", health)
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	print("Slime morreu!")
	queue_free()  # Remove o slime da cena
