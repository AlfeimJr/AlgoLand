extends Node

var weapons = {
	"sword_basic": {
		"name": "Basic Sword",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Arms/swords/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/slash_1.png"),
				"wave_required": 0
			},
			2: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/2/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/2/slash_1.png"),
				"wave_required": 4
			},
			3: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/3/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/3/slash_1.png"),
				"wave_required": 9
			},
			4: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/4/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/4/slash_1.png"),
				"wave_required": 20
			},
			5: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/5/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/5/slash_1.png"),
				"wave_required": 35
			}
		}
	},
	"shield_basic": {
		"name": "Basic Shield",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Arms/shields/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/slash_1.png"),
				"wave_required": 0
			},
			2: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/2/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/2/slash_1.png"),
				"wave_required": 4
			},
			3: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/3/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/3/slash_1.png"),
				"wave_required": 9
			},
			4: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/4/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/4/slash_1.png"),
				"wave_required": 20
			},
			5: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/5/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/5/slash_1.png"),
				"wave_required": 35
			},
		}
	},
	"spear_basic": {
		"name": "Basic Spear",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Arms/spears/spear_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/spears/Attack/slash_1.png"),
				"wave_required": 0
			},
			
		}
	},
	# ... outras armas se necessário
}

func get_weapon_level_data(weapon_id: String, level: int) -> Dictionary:
	if not weapons.has(weapon_id):
		return {}
	var wpn = weapons[weapon_id]
	if not wpn["levels"].has(level):
		return {}
	return wpn["levels"][level]
