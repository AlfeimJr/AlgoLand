extends Node2D

# -- Variáveis gerais --
var esta_aberto: bool = false   # controle de inventário aberto/fechado

# -- Variáveis de Arrastar-e-Soltar --
var esta_arrastando: bool = false
var tipo_item_arrastado: String = ""   # "espada", "lanca" ou "escudo"
var slot_origem_arrasto: Sprite2D
signal item_selecionado(tipo_item: String, textura: Texture2D)

# -- Referência ao jogador (atualizada) --
@onready var jogador = get_node("/root/cenario/Jogador")

# -- Referências aos slots do inventário (nós que exibem o item equipado) --
@onready var slot_espada = $espada_basica/Sprite2D
@onready var slot_lanca = $lanca_basica/Sprite2D
@onready var slot_escudo = $escudo_basico/Sprite2D
@onready var slot_cabeca = $cabeca_basica/Sprite2D
@onready var slot_armadura = $armadura_basica/Sprite2D
@onready var slot_luvas = $luvas_basicas/Sprite2D
@onready var slot_botas = $botas_basicas/Sprite2D

# -- Referências aos nós do "slot vazio" --
@onready var slot_espada_vazio = $slot_espada_vazio
@onready var slot_escudo_vazio = $slot_escudo_vazio
@onready var slot_lanca_vazio = $slot_espada_vazio
@onready var slot_cabeca_vazio = $cabeca
@onready var slot_corpo_vazio = $corpo
@onready var slot_luvas_vazio = $luvas
@onready var slot_bota_vazio = $bota
# -- Referências aos elementos de customização do personagem --
@onready var personalizacao_jogador = $PersonalizacaoJogador
@onready var sprite_cabelo = $PersonalizacaoJogador/Cabelo
@onready var sprite_roupa = $PersonalizacaoJogador/Roupa
@onready var sprite_corpo = $PersonalizacaoJogador/Corpo

func _ready() -> void:
	# Iniciar com o inventário fechado
	fechar()

	# Exemplo: inicia a lança invisível
	if $Item3:
		$Item3.visible = false

	# Conectar sinais do jogador
	if jogador:
		if jogador.has_signal("equipamento_alterado"):
			jogador.connect("equipamento_alterado", Callable(self, "_ao_equipamento_jogador_alterado"))
	else:
		print("Erro: Não foi possível encontrar o nó do jogador!")

func _process(delta: float) -> void:
	# Tecla "i" para abrir/fechar inventário
	if Input.is_action_just_pressed("open_inventory"):
		alternar_inventario()

# Abre/fecha inventário
func alternar_inventario() -> void:
	if esta_aberto:
		fechar()
	else:
		abrir()

func abrir() -> void:
	visible = true
	esta_aberto = true
	atualizar_inventario()
	atualizar_personalizacao_jogador()

func fechar() -> void:
	var itens = get_tree().get_nodes_in_group("itens_arrastaveis")
	for item in itens:
		if item.has_method("resetar_posicao"):
			item.resetar_posicao()
	
	visible = false
	esta_aberto = false
	if jogador:
		print("Inventário fechado em posição: ", jogador.global_position)

# Atualiza os slots de inventário
func atualizar_inventario() -> void:
	if not jogador:
		return

	# Exemplo de debug
	print("Item atual do jogador:", jogador.tipo_item_atual)

	# Limpar texturas dos slots primeiro
	if slot_espada:
		slot_espada.texture = null
	if slot_lanca:
		slot_lanca.texture = null
	if slot_escudo:
		slot_escudo.texture = null

	# Controlar visibilidade dos itens (Item, Item2, Item3) baseado no que está equipado
	# $Item  = espada
	# $Item2 = escudo
	# $Item3 = lança
	if $espada_basica and $lanca_basica:
		if jogador.usando_espada:
			$espada_basica.visible = true   # mostra a espada
			$lanca_basica.visible = false # esconde a lança
		elif jogador.usando_lanca:
			$espada_basica.visible = false
			$lanca_basica.visible = true
		else:
			# Se nenhuma arma estiver equipada, mostra só o "slot" da espada
			$espada_basica.visible = false
			$lanca_basica.visible = false
	
	# Escudo
	if $escudo_basico:
		# Se o jogador estiver usando escudo, mostra; caso contrário, esconde
		$escudo_basico.visible = jogador.usando_escudo

	# Atualizar frames e posições baseado no tipo_item (apenas exemplo)
	if $espada_basica:
		match $espada_basica.tipo_item:
			"espada_basica":
				slot_espada.frame = 42
				slot_espada.position = Vector2(6, 6)
				slot_espada.scale = Vector2(0.7, 0.7)

	if $escudo_basico and $escudo_basico.tipo_item == "escudo_basico":
		slot_escudo.frame = 32
		slot_escudo.position = Vector2(-1, -2)
		slot_escudo.scale = Vector2(0.7, 0.7)

	if $lanca_basica and $lanca_basica.tipo_item == "lanca_basica":
		slot_lanca.frame = 13
		slot_lanca.position = Vector2(3, 2)
		slot_lanca.scale = Vector2(0.4, 0.4)

	# Atualizar texturas baseado no que o jogador está usando
	# (As variáveis jogador.sprite_espada, jogador.sprite_lanca, jogador.sprite_escudo 
	#  devem ser definidas no script do Jogador)
	if jogador.usando_espada and jogador.sprite_espada and jogador.sprite_espada.texture:
		slot_espada.texture = jogador.sprite_espada.texture

	if jogador.usando_lanca and jogador.sprite_lanca and jogador.sprite_lanca.texture:
		slot_lanca.texture = jogador.sprite_lanca.texture

	if jogador.usando_escudo and jogador.sprite_escudo and jogador.sprite_escudo.texture:
		slot_escudo.texture = jogador.sprite_escudo.texture

	# --- CABEÇA ---
	if jogador.sprite_armadura_cabeca and jogador.sprite_armadura_cabeca.texture:
		# 1) Atribui a textura
		slot_cabeca.texture = jogador.sprite_armadura_cabeca.texture
		# 2) Garante hframes e vframes = 1
		slot_cabeca.hframes = 1
		slot_cabeca.vframes = 1
		# 3) Ajusta o scale para 0.7
		slot_cabeca.scale = Vector2(0.7, 0.7)
		# 4) Ajusta position para (0,0)
		slot_cabeca.position = Vector2.ZERO
	else:
		slot_cabeca.texture = null
		slot_cabeca.hframes = 1
		slot_cabeca.vframes = 1
		slot_cabeca.scale = Vector2(0.7, 0.7)
		slot_cabeca.position = Vector2.ZERO

# --- CORPO (ARMADURA) ---
	if jogador.sprite_armadura_corpo and jogador.sprite_armadura_corpo.texture:
		slot_armadura.texture = jogador.sprite_armadura_corpo.texture
		slot_armadura.hframes = 1
		slot_armadura.vframes = 1
		slot_armadura.scale = Vector2(0.7, 0.7)
		slot_armadura.position = Vector2.ZERO
	else:
		slot_armadura.texture = null
		slot_armadura.hframes = 1
		slot_armadura.vframes = 1
		slot_armadura.scale = Vector2(0.7, 0.7)
		slot_armadura.position = Vector2.ZERO

# --- LUVAS ---
	if jogador.sprite_armadura_luvas and jogador.sprite_armadura_luvas.texture:
		slot_luvas.texture = jogador.sprite_armadura_luvas.texture
		slot_luvas.hframes = 1
		slot_luvas.vframes = 1
		slot_luvas.scale = Vector2(0.7, 0.7)
		slot_luvas.position = Vector2.ZERO
	else:
		slot_luvas.texture = null
		slot_luvas.hframes = 1
		slot_luvas.vframes = 1
		slot_luvas.scale = Vector2(0.7, 0.7)
		slot_luvas.position = Vector2.ZERO

# --- BOTAS ---
	if jogador.sprite_armadura_botas and jogador.sprite_armadura_botas.texture:
		slot_botas.texture = jogador.sprite_armadura_botas.texture
		slot_botas.hframes = 1
		slot_botas.vframes = 1
		slot_botas.scale = Vector2(0.7, 0.7)
		slot_botas.position = Vector2.ZERO
	else:
		slot_botas.texture = null
		slot_botas.hframes = 1
		slot_botas.vframes = 1
		slot_botas.scale = Vector2(0.7, 0.7)
		slot_botas.position = Vector2.ZERO
	atualizar_personalizacao_jogador()

func atualizar_personalizacao_jogador() -> void:
	if not jogador:
		return
	
	# Atualizar sprite de cabelo
	if sprite_cabelo and jogador.sprite_cabelo:
		sprite_cabelo.texture = jogador.sprite_cabelo.texture
		sprite_cabelo.modulate = jogador.cor_cabelo
	
	# Atualizar sprite de roupa
	if sprite_roupa and jogador.sprite_roupa:
		sprite_roupa.texture = jogador.sprite_roupa.texture
	
	# Atualizar sprite do corpo
	if sprite_corpo and jogador.sprite_corpo:
		sprite_corpo.texture = jogador.sprite_corpo.texture

# Chamado quando o sinal "equipamento_alterado" do Jogador é emitido
func _ao_equipamento_jogador_alterado() -> void:
	atualizar_inventario()
