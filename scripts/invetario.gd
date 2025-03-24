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
@onready var sword_slot = $Item/Sprite2D
@onready var spear_slot = $Item3/Sprite2D
@onready var shield_slot = $Item2/Sprite2D

# -- Referências aos nós do "slot vazio" --
@onready var sword_slot_empty = $sword_slot_empty
@onready var shield_slot_empty = $shield_slot_empty
@onready var spear_slot_empty = $sword_slot_empty

# -- Referências aos elementos de customização do personagem --
@onready var player_customization = $Panel/PlayerCustomization
@onready var hair_sprite = $Panel/PlayerCustomization/Hair
@onready var outfit_sprite = $Panel/PlayerCustomization/Outfit
@onready var body_sprite = $Panel/PlayerCustomization/Body

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
	if $Item and $Item3:
		if player.using_sword:
			$Item.visible = true   # mostra a espada
			$Item3.visible = false # esconde a lança
		elif player.using_spear:
			$Item.visible = false
			$Item3.visible = true
		else:
			# Se nenhuma arma estiver equipada, mostra só o "slot" da espada
			$Item.visible = false
			$Item3.visible = false
	
	# Escudo
	if $Item2:
		# Se o jogador estiver usando escudo, mostra; caso contrário, esconde
		$Item2.visible = player.using_shield

	# Atualizar frames e posições baseado no item_type (apenas exemplo)
	if $Item:
		match $Item.item_type:
			"sword_basic":
				sword_slot.frame = 42
				sword_slot.position = Vector2(6, 6)
				sword_slot.scale = Vector2(0.7, 0.7)

	if $Item2 and $Item2.item_type == "shield_basic":
		shield_slot.frame = 32
		shield_slot.position = Vector2(-1, -2)
		shield_slot.scale = Vector2(0.7, 0.7)

	if $Item3 and $Item3.item_type == "spear_basic":
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

	# ---- LÓGICA PARA SLOTS VAZIOS ----
	# Se o jogador estiver usando espada, esconde o slot vazio de espada
	# e assim por diante para escudo e lança.
	if sword_slot_empty:
		sword_slot_empty.visible = not player.using_sword
	if shield_slot_empty:
		shield_slot_empty.visible = not player.using_shield
	if spear_slot_empty:
		spear_slot_empty.visible = not player.using_spear and not player.using_sword

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
