extends Node2D

# -- Variáveis gerais --
var is_open: bool = false   # controle de inventário aberto/fechado

# -- Variáveis de Drag-and-Drop --
var is_dragging: bool = false
var drag_item_type: String = ""   # "sword", "spear" ou "shield"
var drag_origin_slot: Sprite2D
signal item_selected(item_type: String, texture: Texture2D)

# -- Referência ao jogador (atualizada) --
@onready var player = get_node("/root/cenario/Player")

# -- Referências aos slots do inventário (nós que exibem o item equipado) --
@onready var sword_slot = $sword_basic/Sprite2D
@onready var spear_slot = $spear_basic/Sprite2D
@onready var shield_slot = $shield_basic/Sprite2D
@onready var head_slot = $head_basic/Sprite2D
@onready var armor_slot = $armor_basic/Sprite2D
@onready var gloves_slot = $gloves_basic/Sprite2D
@onready var boots_slot = $boots_basic/Sprite2D

# -- Referências aos nós do "slot vazio" --
@onready var sword_slot_empty = $sword_slot_empty
@onready var shield_slot_empty = $shield_slot_empty
@onready var spear_slot_empty = $sword_slot_empty
@onready var head_slot_empty = $head
@onready var body_slot_empty = $body
@onready var gloves_slot_empty = $gloves
@onready var boot_slot_empty = $boot
# -- Referências aos elementos de customização do personagem --
@onready var player_customization = $PlayerCustomization
@onready var hair_sprite = $PlayerCustomization/Hair
@onready var outfit_sprite = $PlayerCustomization/Outfit
@onready var body_sprite = $PlayerCustomization/Body

func _ready() -> void:
	# Iniciar com o inventário fechado
	close()

	# Exemplo: inicia a lança invisível
	if $Item3:
		$Item3.visible = false

	# Conectar sinais do jogador
	if player:
		if player.has_signal("equipment_changed"):
			player.connect("equipment_changed", Callable(self, "_on_player_equipment_changed"))
	else:
		print("Erro: Não foi possível encontrar o nó do jogador!")

func _process(delta: float) -> void:
	# Tecla "i" para abrir/fechar inventário
	if Input.is_action_just_pressed("open_inventory"):
		toggle_inventory()

# Abre/fecha inventário
func toggle_inventory() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	visible = true
	is_open = true
	update_inventory()
	update_player_customization()

func close() -> void:
	var items = get_tree().get_nodes_in_group("draggable_items")
	for item in items:
		if item.has_method("reset_position"):
			item.reset_position()
	
	visible = false
	is_open = false
	if player:
		print("Inventário fechado em posição: ", player.global_position)

# Atualiza os slots de inventário
func update_inventory() -> void:
	if not player:
		return

	# Exemplo de debug
	print("Item atual do player:", player.current_item_type)

	# Limpar texturas dos slots primeiro
	if sword_slot:
		sword_slot.texture = null
	if spear_slot:
		spear_slot.texture = null
	if shield_slot:
		shield_slot.texture = null

	# Controlar visibilidade dos itens (Item, Item2, Item3) baseado no que está equipado
	# $Item  = espada
	# $Item2 = escudo
	# $Item3 = lança
	if $sword_basic and $spear_basic:
		if player.using_sword:
			$sword_basic.visible = true   # mostra a espada
			$spear_basic.visible = false # esconde a lança
		elif player.using_spear:
			$sword_basic.visible = false
			$spear_basic.visible = true
		else:
			# Se nenhuma arma estiver equipada, mostra só o "slot" da espada
			$sword_basic.visible = false
			$spear_basic.visible = false
	
	# Escudo
	if $shield_basic:
		# Se o jogador estiver usando escudo, mostra; caso contrário, esconde
		$shield_basic.visible = player.using_shield

	# Atualizar frames e posições baseado no item_type (apenas exemplo)
	if $sword_basic:
		match $sword_basic.item_type:
			"sword_basic":
				sword_slot.frame = 42
				sword_slot.position = Vector2(6, 6)
				sword_slot.scale = Vector2(0.7, 0.7)

	if $shield_basic and $shield_basic.item_type == "shield_basic":
		shield_slot.frame = 32
		shield_slot.position = Vector2(-1, -2)
		shield_slot.scale = Vector2(0.7, 0.7)

	if $spear_basic and $spear_basic.item_type == "spear_basic":
		spear_slot.frame = 13
		spear_slot.position = Vector2(3, 2)
		spear_slot.scale = Vector2(0.4, 0.4)

	# Atualizar texturas baseado no que o jogador está usando
	# (As variáveis player.sword_sprite, player.spear_sprite, player.shield_sprite 
	#  devem ser definidas no script do Player)
	if player.using_sword and player.sword_sprite and player.sword_sprite.texture:
		sword_slot.texture = player.sword_sprite.texture

	if player.using_spear and player.spear_sprite and player.spear_sprite.texture:
		spear_slot.texture = player.spear_sprite.texture

	if player.using_shield and player.shield_sprite and player.shield_sprite.texture:
		shield_slot.texture = player.shield_sprite.texture

	# --- HEAD ---
	if player.armor_head_sprite and player.armor_head_sprite.texture:
		# 1) Atribui a textura
		head_slot.texture = player.armor_head_sprite.texture
		# 2) Garante hframes e vframes = 1
		head_slot.hframes = 1
		head_slot.vframes = 1
		# 3) Ajusta o scale para 0.7
		head_slot.scale = Vector2(0.7, 0.7)
		# 4) Ajusta position para (0,0)
		head_slot.position = Vector2.ZERO
	else:
		head_slot.texture = null
		head_slot.hframes = 1
		head_slot.vframes = 1
		head_slot.scale = Vector2(0.7, 0.7)
		head_slot.position = Vector2.ZERO

# --- CORPO (ARMOR) ---
	if player.armor_body_sprite and player.armor_body_sprite.texture:
		armor_slot.texture = player.armor_body_sprite.texture
		armor_slot.hframes = 1
		armor_slot.vframes = 1
		armor_slot.scale = Vector2(0.7, 0.7)
		armor_slot.position = Vector2.ZERO
	else:
		armor_slot.texture = null
		armor_slot.hframes = 1
		armor_slot.vframes = 1
		armor_slot.scale = Vector2(0.7, 0.7)
		armor_slot.position = Vector2.ZERO

# --- GLOVES ---
	if player.armor_gloves_sprite and player.armor_gloves_sprite.texture:
		gloves_slot.texture = player.armor_gloves_sprite.texture
		gloves_slot.hframes = 1
		gloves_slot.vframes = 1
		gloves_slot.scale = Vector2(0.7, 0.7)
		gloves_slot.position = Vector2.ZERO
	else:
		gloves_slot.texture = null
		gloves_slot.hframes = 1
		gloves_slot.vframes = 1
		gloves_slot.scale = Vector2(0.7, 0.7)
		gloves_slot.position = Vector2.ZERO

# --- BOOTS ---
	if player.armor_boots_sprite and player.armor_boots_sprite.texture:
		boots_slot.texture = player.armor_boots_sprite.texture
		boots_slot.hframes = 1
		boots_slot.vframes = 1
		boots_slot.scale = Vector2(0.7, 0.7)
		boots_slot.position = Vector2.ZERO
	else:
		boots_slot.texture = null
		boots_slot.hframes = 1
		boots_slot.vframes = 1
		boots_slot.scale = Vector2(0.7, 0.7)
		boots_slot.position = Vector2.ZERO
	update_player_customization()

func update_player_customization() -> void:
	if not player:
		return
	
	# Atualizar sprite de cabelo
	if hair_sprite and player.hairSprite:
		hair_sprite.texture = player.hairSprite.texture
		hair_sprite.modulate = player.hair_color
	
	# Atualizar sprite de roupa
	if outfit_sprite and player.outfit_sprite:
		outfit_sprite.texture = player.outfit_sprite.texture
	
	# Atualizar sprite do corpo
	if body_sprite and player.bodySprite:
		body_sprite.texture = player.bodySprite.texture

# Chamado quando o sinal "equipment_changed" do Player é emitido
func _on_player_equipment_changed() -> void:
	update_inventory()
