extends Node2D

signal customization_finished(hair_index: int, outfit_index: int, color: Color, nickname: String)

var hair_color: Color = Color(1, 1, 1, 1)
var nickname: String = ""
var curr_hair: int = 0
var curr_outfit: int = 0

# Arrays de texturas para cada tipo de cabelo/outfit
var hair_sprites: Array[Texture2D] = []
var outfit_sprites: Array[Texture2D] = []

@onready var hairSprite: Sprite2D = $Hair
@onready var outfitSprite: Sprite2D = $Outfit

func _ready() -> void:
	# 1) Carrega as sprites de cabelo (exemplo de 1 a 27)
	for i in range(1, 3):
		var hair_path = "res://CharacterSprites/Hair/hair (%d).png" % i
		var hair_res = load(hair_path)
		if hair_res:
			hair_sprites.append(hair_res)
	
	# 2) Carrega as sprites de roupa (exemplo de 1 a 8)
	for i in range(1, 9):
		var outfit_path = "res://CharacterSprites/Outfit/outfit (%d).png" % i
		var outfit_res = load(outfit_path)
		if outfit_res:
			outfit_sprites.append(outfit_res)

	# (Opcional) Se quiser também arrays para "hair_attack_array" ou "outfit_attack_array",
	# faça do mesmo jeito, mas lembre que, na customização, geralmente basta ver a sprite "idle".

	# Por fim, atualiza a aparência inicial
	update_visuals()

# ---------------------------
# TROCA DE COR
# ---------------------------
func set_hair_color(new_color: Color) -> void:
	hair_color = new_color
	if hairSprite:
		hairSprite.modulate = new_color

# ---------------------------
# TROCA DE CABELO
# ---------------------------
func change_hair_forward() -> void:
	if hair_sprites.size() > 0:
		curr_hair = (curr_hair + 1) % hair_sprites.size()
		update_visuals()

func change_hair_backward() -> void:
	if hair_sprites.size() > 0:
		curr_hair = (curr_hair - 1) % hair_sprites.size()
		if curr_hair < 0:
			curr_hair = hair_sprites.size() - 1
		update_visuals()

# ---------------------------
# TROCA DE ROUPA
# ---------------------------
func change_outfit_forward() -> void:
	if outfit_sprites.size() > 0:
		curr_outfit = (curr_outfit + 1) % outfit_sprites.size()
		update_visuals()

func change_outfit_backward() -> void:
	if outfit_sprites.size() > 0:
		curr_outfit = (curr_outfit - 1) % outfit_sprites.size()
		if curr_outfit < 0:
			curr_outfit = outfit_sprites.size() - 1
		update_visuals()

# ---------------------------
# DEFINIR NICKNAME
# ---------------------------
func set_nickname(new_nickname: String) -> void:
	nickname = new_nickname

# ---------------------------
# ATUALIZAR SPRITES
# ---------------------------
func update_visuals() -> void:
	# Se tiver cabelo no array, atualiza sprite
	if hair_sprites.size() > 0 and curr_hair < hair_sprites.size():
		hairSprite.texture = hair_sprites[curr_hair]

	# Se tiver roupa no array, atualiza sprite
	if outfit_sprites.size() > 0 and curr_outfit < outfit_sprites.size():
		outfitSprite.texture = outfit_sprites[curr_outfit]

	# Aplica a cor no cabelo
	hairSprite.modulate = hair_color

# ---------------------------
# SALVAR CUSTOMIZAÇÃO
# ---------------------------
func save_customization():
	emit_signal("customization_finished", curr_hair, curr_outfit, hair_color, nickname)
