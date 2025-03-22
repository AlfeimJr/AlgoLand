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

# -- Referências aos slots do inventário --
@onready var sword_slot = $Item/Sprite2D
@onready var spear_slot = $Item/Sprite2D
@onready var shield_slot = $Item2/Sprite2D

# -- Referências aos elementos de customização do personagem --
@onready var player_customization = $Panel/PlayerCustomization
@onready var hair_sprite = $Panel/PlayerCustomization/Hair
@onready var outfit_sprite = $Panel/PlayerCustomization/Outfit
@onready var body_sprite = $Panel/PlayerCustomization/Body

func _ready() -> void:
	# Iniciar com o inventário fechado
	close()
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

# Atualiza os slots de inventário
func update_inventory() -> void:
	if not player:
		return
	if sword_slot:
		# Verifica que tipo de arma o jogador está usando
		# e define o frame. Ajuste os números conforme a sua spritesheet.
		match player.current_item_type:  # "sword", "shield", "spear", etc.
			"sword":
				sword_slot.frame = 42
				sword_slot.position = Vector2(6, 6)
			"shield":
				shield_slot.frame = 32
				shield_slot.position = Vector2(-1, -4)
			"spear":
				sword_slot.frame = 2
	# Limpar slots
	if sword_slot:
		sword_slot.texture = null
	if spear_slot:
		spear_slot.texture = null
	if shield_slot:
		shield_slot.texture = null
	
	# Se o jogador estiver usando espada
	if player.using_sword:
		if player.sword_sprite and player.sword_sprite.texture:
			sword_slot.texture = player.sword_sprite.texture
		if player.shield_sprite and player.shield_sprite.texture:
			shield_slot.texture = player.shield_sprite.texture	
	
	# Se estiver usando lança
	if player.using_spear:
		if player.spear_sprite and player.spear_sprite.texture:
			spear_slot.texture = player.spear_sprite.texture
	
	update_player_customization()

func update_player_customization() -> void:
	if not player:
		return
	
	if hair_sprite and player.hairSprite:
		hair_sprite.texture = player.hairSprite.texture
		hair_sprite.modulate = player.hair_color
	
	if outfit_sprite and player.outfit_sprite:
		outfit_sprite.texture = player.outfit_sprite.texture
	
	if body_sprite and player.bodySprite:
		body_sprite.texture = player.bodySprite.texture
