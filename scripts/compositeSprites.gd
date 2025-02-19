extends Node
class_name Composite

var body_spriteSheet = {}
var hair_spriteSheet = {}
var outfit_spriteSheet = {}
func _init():
	# Inicializa o body_spriteSheet (exemplo)
	body_spriteSheet = {
		0: load("res://CharacterSprites/Body/body_1.png"),
		1: load("res://CharacterSprites/Body/body_2.png"),
		2: load("res://CharacterSprites/Body/body_3.png")
	}
	
	# Supondo que você tenha arquivos de hair (1).png até hair (107).png
	for i in range(1, 28):  # i vai de 1 até 107
		var resource = load("res://CharacterSprites/Hair/hair (" + str(i) + ").png")
		if resource:
			# Se quiser que hair(1).png fique na chave 0, use i - 1
			hair_spriteSheet[i - 1] = resource
		else:
			print("Não foi possível carregar: res://CharacterSprites/Hair/hair (" + str(i) + ").png")
			
	for i in range(1, 3):  # i vai de 1 até 107
		var resource = load("res://CharacterSprites/Outfit/outfit (" + str(i) + ").png")
		if resource:
			# Se quiser que hair(1).png fique na chave 0, use i - 1
			outfit_spriteSheet[i - 1] = resource
		else:
			print("Não foi possível carregar: res://CharacterSprites/Outfit/outfit (" + str(i) + ").png")
