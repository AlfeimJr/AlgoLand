extends CharacterBody2D
class_name InimigoBase

# -----------------------------
# CONFIGURAÇÕES DE MOVIMENTO
# -----------------------------
@export var velocidade: int = 30
@export var velocidade_patrulha: int = 20
@export var alcance_separacao: float = 50.0
@export var forca_separacao: float = 20.0
var direcao: Vector2 = Vector2.ZERO
var ultima_direcao_horizontal: float = 1.0  # 1 para direita, -1 para esquerda

# -----------------------------
# CONFIGURAÇÕES DE ATAQUE
# -----------------------------
@export var tempo_recarga_ataque: float = 1.5
@export var alcance_ataque: float = 20.0   # Distância mínima para que o attack animado seja priorizado
var pode_atacar: bool = true
var dano: float = 15

# -----------------------------
# VARIÁVEIS DE VIDA
# -----------------------------
@export var vida: int = 25
var esta_morto: bool = false

# -----------------------------
# ESTADOS
# -----------------------------
var esta_perseguindo: bool = false
var esta_recuando: bool = false
var esta_danificado: bool = false
var esta_patrulhando: bool = true
var direcao_patrulha: Vector2 = Vector2.RIGHT
var temporizador_patrulha: float = 0.0
@export var duracao_patrulha: float = 2.0
@export var distancia_minima: float = 10.0

# Flag para indicar se o player está na área de ataque.
var na_area_ataque: bool = false

# Flag para indicar se o inimigo está atacando.
var esta_atacando: bool = false

# -----------------------------
# NÓS DE ANIMAÇÃO E COLISÃO
# -----------------------------
@onready var arvore_animacao: AnimationTree = $AnimationTree
@onready var estado_animacao = arvore_animacao.get("parameters/playback")
@onready var posicao_blend = arvore_animacao.get("parameters/run/blend_position")
@onready var sprite = $Texture  # Nó do sprite para efeito de piscar

signal atingiu_jogador
signal inimigo_morreu

func _ready() -> void:
	# Ativa a AnimationTree e define o estado "run"
	if arvore_animacao:
		arvore_animacao.active = true
		definir_animacao("run")
	
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
		var cena_barra_hp = preload("res://cenas/barra-de-vida.tscn")
		var instancia_barra_hp = cena_barra_hp.instantiate()
		instancia_barra_hp.name = "HPBar"
		add_child(instancia_barra_hp)
		# Posiciona a barra acima do inimigo (ajuste conforme necessário)
		instancia_barra_hp.position = Vector2(0, -40)

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

func calcular_separacao() -> Vector2:
	var vetor_repulsao = Vector2.ZERO
	var contador_vizinhos = 0
	for outro in get_tree().get_nodes_in_group("enemy"):
		if outro != self:
			var dist = position.distance_to(outro.position)
			if dist < alcance_separacao:
				var diff = (position - outro.position).normalized()
				vetor_repulsao += diff / dist
				contador_vizinhos += 1
	if contador_vizinhos > 0:
		vetor_repulsao /= float(contador_vizinhos)
		vetor_repulsao *= forca_separacao
	return vetor_repulsao

func receber_dano(quantidade_dano: int, forca_knockback: Vector2 = Vector2.ZERO) -> void:
	if esta_morto:
		return

	vida -= quantidade_dano

	# Exibe texto de dano flutuante
	gerar_rotulo_dano(quantidade_dano)
	
	# Atualiza a barra de HP, se existir
	if has_node("HPBar"):
		get_node("HPBar").atualizar_barra(vida)

	# Verifica se o inimigo morreu
	if vida <= 0:
		morrer()
		return

	# Se não estiver atacando, volta a animação para "run"
	if not esta_atacando:
		definir_animacao("run")

	# Se não foi passado forca_knockback, calcula um padrão
	if forca_knockback == Vector2.ZERO:
		forca_knockback = (position - obter_jogador().position).normalized() * 300.0

	# Aplica o knockback (recuo)
	esta_recuando = true
	velocity = forca_knockback
	move_and_slide()

	# Espera um pouco (0.3s) para manter o knockback
	await get_tree().create_timer(0.3).timeout
	esta_recuando = false
	velocity = Vector2.ZERO

	# Pisca para indicar dano
	piscar_dano()

	# Espera mais um pouco antes de voltar para a animação "run"
	await get_tree().create_timer(0.5).timeout
	if not esta_atacando:
		definir_animacao("run")

func piscar_dano() -> void:
	for i in range(5):
		sprite.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func morrer() -> void:
	if esta_morto:
		return
	esta_morto = true
	definir_animacao("dead")
	await get_tree().create_timer(0.2).timeout
	emit_signal("inimigo_morreu")
	queue_free()

func definir_animacao(nome_animacao: String) -> void:
	if not arvore_animacao or not estado_animacao:
		return
	if estado_animacao.get_current_node() == nome_animacao:
		return
	estado_animacao.travel(nome_animacao)

func definir_direcao_animacao(dir: Vector2) -> void:
	if not arvore_animacao:
		return
	if dir.x < 0:
		ultima_direcao_horizontal = -1.0
	elif dir.x > 0:
		ultima_direcao_horizontal = 1.0

	posicao_blend.x = ultima_direcao_horizontal
	posicao_blend.y = 0
	arvore_animacao.set("parameters/run/blend_position", posicao_blend)

func definir_escala_deteccao(escala: float) -> void:
	var area_deteccao = get_node_or_null("DetectionArea")
	if area_deteccao:
		var colisao = area_deteccao.get_node_or_null("CollisionShape2D")
		if colisao and colisao.shape is RectangleShape2D:
			var retangulo = colisao.shape as RectangleShape2D
			retangulo.extents *= escala
			colisao.shape = retangulo

func obter_dano() -> int:
	return dano

# Para ser sobrescrito nos filhos (Ex: SlimeEscorregadio.gd)
func obter_jogador() -> Node2D:
	return null

# -----------------------------
# DETECÇÃO DO JOGADOR
# -----------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == obter_jogador():
		esta_perseguindo = true
		esta_patrulhando = false
		atingiu_jogador.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == obter_jogador():
		if not na_area_ataque:
			esta_perseguindo = false
			esta_patrulhando = true
			temporizador_patrulha = 0.0
			direcao_patrulha = Vector2.RIGHT

# -------------------------------------------------
# FUNÇÃO PARA CRIAR O TEXTO DE DANO ACIMA DO INIMIGO
# -------------------------------------------------
func gerar_rotulo_dano(valor_dano: int) -> void:
	var cena_rotulo = preload("res://cenas/dano-flutuante.tscn")
	var instancia_rotulo = cena_rotulo.instantiate()

	# Posição do Node2D (a cena do texto)
	instancia_rotulo.global_position = global_position - Vector2(0, 20)

	# Chama o método 'definir_dano' do script
	instancia_rotulo.definir_dano(valor_dano)

	# Adiciona na cena
	get_tree().current_scene.add_child(instancia_rotulo)
