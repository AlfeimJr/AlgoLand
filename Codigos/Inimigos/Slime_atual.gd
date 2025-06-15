extends "Inimigo-base.gd"
class_name SlimeEscorregadio
var esta_atacando_atualmente = false
@onready var jogador = get_node("/root/cenario/Jogador")

func _ready() -> void:
	# Chama o _ready() do pai (BaseInimigo)
	super()
	# Ativa a AnimationTree se houver e define o estado "run"
	if arvore_animacao:
		arvore_animacao.active = true
		definir_animacao("run")
	# Configura a área de ATAQUE
	if $area_ataque:
		$area_ataque.monitoring = true
		$area_ataque.monitorable = true
		$area_ataque.set_collision_mask_value(1, true)
		
		if not $area_ataque.is_connected("body_entered", Callable(self, "_on_area_ataque_body_entered")):
			$area_ataque.connect("body_entered", Callable(self, "_on_area_ataque_body_entered"))
		if not $area_ataque.is_connected("body_exited", Callable(self, "_on_area_ataque_body_exited")):
			$area_ataque.connect("body_exited", Callable(self, "_on_area_ataque_body_exited"))
		
		# Desabilita inicialmente a hitbox de ataque
		if $area_ataque.has_node("colisao_ataque"):
			var colisao_ataque = $area_ataque.get_node("colisao_ataque")
			colisao_ataque.disabled = true
		
	# Configura a área de dano ao jogador
	if $ataque:
		$ataque.monitoring = true
		$ataque.monitorable = true
		$ataque.set_collision_mask_value(1, true)
		
		if not $ataque.is_connected("body_entered", Callable(self, "_on_colisao_ataque_jogador_body_entered")):
			$ataque.connect("body_entered", Callable(self, "_on_colisao_ataque_jogador_body_entered"))
		
		# Desabilita inicialmente a hitbox de dano
		if $ataque.has_node("colisao_ataque_jogador"):
			var colisao_ataque_jogador = $ataque.get_node("colisao_ataque_jogador")
			colisao_ataque_jogador.disabled = true

func _physics_process(delta: float) -> void:
	# Não chama super() para evitar a lógica da classe base que impede movimento durante ataque
	if esta_morto or not has_method("obter_jogador"):
		return
	
	var velocidade_base = Vector2.ZERO

	# Se estiver recuando (knockback)
	if esta_recuando:
		move_and_slide()
		return

	# MODO PATRULHA
	if esta_patrulhando:
		temporizador_patrulha += delta
		if temporizador_patrulha >= duracao_patrulha:
			temporizador_patrulha = 0.0
			direcao_patrulha = -direcao_patrulha
		definir_direcao_animacao(direcao_patrulha)
		velocidade_base = direcao_patrulha * velocidade_patrulha + calcular_separacao()

	# PERSEGUIÇÃO
	elif esta_perseguindo:
		var jogador = obter_jogador()
		if jogador:
			var distancia_para_jogador = position.distance_to(jogador.position)
			if distancia_para_jogador > distancia_minima:
				direcao = (jogador.position - position).normalized()
				definir_direcao_animacao(direcao)
			else:
				direcao = Vector2.ZERO
				velocidade_base = Vector2.ZERO

			velocidade_base = direcao * velocidade
	else:
		velocidade_base = Vector2.ZERO
		definir_direcao_animacao(Vector2(ultima_direcao_horizontal, 0))

	velocity = velocidade_base
	move_and_slide()

# --------------------------------------------------
#  SINAIS DA ÁREA DE DETECÇÃO (PERSEGUIÇÃO)
# --------------------------------------------------
func _on_detection_area_body_entered(body: Node) -> void:
	if body == jogador:
		esta_perseguindo = true
		esta_patrulhando = false

func _on_detection_area_body_exited(body: Node) -> void:
	if body == jogador:
		esta_perseguindo = false
		esta_patrulhando = true
		temporizador_patrulha = 0.0
		direcao_patrulha = Vector2.RIGHT

# --------------------------------------------------
#  SINAIS DA ÁREA DE ATAQUE
# --------------------------------------------------
func _on_area_ataque_body_entered(body: Node) -> void:
	if body == jogador:
		na_area_ataque = true
		esta_perseguindo = true
		esta_patrulhando = false
		if pode_atacar and not esta_morto:
			atacar_jogador()

func _on_area_ataque_body_exited(body: Node) -> void:
	if body == jogador:
		na_area_ataque = false

# Função para quando o jogador entra na área de colisão que dá dano
func _on_colisao_ataque_jogador_body_entered(body: Node) -> void:
	if body == jogador:
		# Aplica dano ao jogador
		if body.has_method("receber_dano"):
			# Calcula a direção do knockback (do inimigo para o jogador)
			var direcao_knockback = (jogador.position - position).normalized()
			# Define a força do knockback
			var forca_knockback = direcao_knockback * 150.0
			
			# Aplica dano com o knockback
			body.receber_dano(obter_dano(), forca_knockback)
			emit_signal("atingiu_jogador")

# --------------------------------------------------
#  LÓGICA DE ATAQUE (usando estado único "attack" com blend)
# --------------------------------------------------
func atacar_jogador() -> void:
	if esta_atacando_atualmente:
		return
		
	esta_atacando_atualmente = true
	esta_atacando = true
	pode_atacar = false
	
	# Calcula o vetor em direção ao jogador
	var dir_para_jogador = jogador.position - position
	
	# Viaja para o estado "attack" no AnimationTree
	definir_animacao("attack")
	
	# Ajusta o blend para definir a direção do ataque
	var vetor_blend = Vector2.ZERO
	if abs(dir_para_jogador.x) > abs(dir_para_jogador.y):
		vetor_blend.x = sign(dir_para_jogador.x)  # +1 para direita, -1 para esquerda
	else:
		vetor_blend.y = sign(dir_para_jogador.y)  # +1 para baixo, -1 para cima
	
	arvore_animacao.set("parameters/attack/blend_position", vetor_blend)
	
	# Ativa a hitbox de dano no momento certo da animação
	await get_tree().create_timer(0.1).timeout
	
	# Ativa a hitbox de dano (colisao_ataque_jogador)
	if $ataque and $ataque.has_node("colisao_ataque_jogador"):
		var colisao_ataque_jogador = $ataque.get_node("colisao_ataque_jogador")
		colisao_ataque_jogador.disabled = false
	
	# Aguarda a duração da animação de ataque
	await get_tree().create_timer(0.2).timeout
	
	# Desativa a hitbox de dano
	if $ataque and $ataque.has_node("colisao_ataque_jogador"):
		var colisao_ataque_jogador = $ataque.get_node("colisao_ataque_jogador")
		colisao_ataque_jogador.disabled = true
	
	# Muda para a animação de run após o ataque
	definir_animacao("run")
	
	# Aguarda o cooldown de 2 segundos
	await get_tree().create_timer(2.0).timeout
	
	# Libera o ataque após o cooldown
	pode_atacar = true
	esta_atacando = false
	esta_atacando_atualmente = false

func obter_jogador() -> Node2D:
	return jogador

# Adicionando um print para verificar quando o inimigo é eliminado
func _exit_tree() -> void:
	print("SlimeEscorregadio eliminado: ", self.name)
