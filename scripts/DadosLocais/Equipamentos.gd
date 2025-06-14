extends Node

var weapons = {
	# ==========================
	# 1) ARMAS JA EXISTENTES
	# ==========================

	"sword_basic": {
		"name": "Basic Sword",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Arms/swords/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/slash_1.png"),
				"wave_required": 0,
				"strength_bonus": 5,
				"damage": 10  
			},
			2: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/2/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/2/slash_1.png"),
				"wave_required": 4,
				"strength_bonus": 10,
				"damage": 20
			},
			3: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/3/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/3/slash_1.png"),
				"wave_required": 9,
				"strength_bonus": 15,
				"damage": 30
			},
			4: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/4/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/4/slash_1.png"),
				"wave_required": 20,
				"strength_bonus": 20,
				"damage": 40
			},
			5: {
				"texture": preload("res://CharacterSprites/Arms/swords/swords_upgraded/5/Sword_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/5/slash_1.png"),
				"wave_required": 35,
				"strength_bonus": 25,
				"damage": 50
			}
		}
	},

	"shield_basic": {
		"name": "Basic Shield",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Arms/shields/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/slash_1.png"),
				"wave_required": 0,
				"vitality_bonus": 2,
				"defense_bonus": 1
			},
			2: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/2/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/2/slash_1.png"),
				"wave_required": 4,
				"vitality_bonus": 5,
				"defense_bonus": 2
			},
			3: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/3/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/3/slash_1.png"),
				"wave_required": 9,
				"vitality_bonus": 10,
				"defense_bonus": 4
			},
			4: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/4/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/4/slash_1.png"),
				"wave_required": 20,
				"vitality_bonus": 12,
				"defense_bonus": 6
			},
			5: {
				"texture": preload("res://CharacterSprites/Arms/shields/shields_upgraded/5/shield_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/5/slash_1.png"),
				"wave_required": 35,
				"vitality_bonus": 15,
				"defense_bonus": 8
			}
		}
	},

	"spear_basic": {
		"name": "Basic Spear",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Arms/spears/spear_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/spears/Attack/slash_1.png"),
				"wave_required": 0,
				"strength_bonus": 15,
				"damage": 30  
			},
			2: {
				"texture": preload("res://CharacterSprites/Arms/spears/spears_upgraded/2/spear_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/2/slash_1.png"),
				"wave_required": 4,
				"strength_bonus": 20,
				"damage": 40  
			},
			3: {
				"texture": preload("res://CharacterSprites/Arms/spears/spears_upgraded/3/spear_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/3/slash_1.png"),
				"wave_required": 9,
				"strength_bonus": 25,
				"damage": 50  
			},
			4: {
				"texture": preload("res://CharacterSprites/Arms/spears/spears_upgraded/4/spear_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/4/slash_1.png"),
				"wave_required": 20,
				"strength_bonus": 30,
				"damage": 60  
			},
			5: {
				"texture": preload("res://CharacterSprites/Arms/spears/spears_upgraded/5/spear_1.png"),
				"attack_texture": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/5/slash_1.png"),
				"wave_required": 35,
				"strength_bonus": 35,
				"damage": 65  
			}
		}
	},

	# ===================================
	# 2) NOVOS ITENS: PARTES DE ARMADURA
	# ===================================

	

	# ... você pode adicionar mais armas/armaduras aqui ...
}

var armors = {
	"armor_head": {
		"name": "Helmet",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Armors/1/head.png"),
				"wave_required": 0,
				"vitality_bonus": 5,
				"defense_bonus": 2
			},
			2: {
				"texture": preload("res://CharacterSprites/Armors/2/head.png"),
				"wave_required": 4,
				"vitality_bonus": 10,
				"defense_bonus": 4
			},
			3: {
				"texture": preload("res://CharacterSprites/Armors/3/head.png"),
				"wave_required": 9,
				"vitality_bonus": 15,
				"defense_bonus": 6
			},
			4: {
				"texture": preload("res://CharacterSprites/Armors/4/head.png"),
				"wave_required": 20,
				"vitality_bonus": 20,
				"defense_bonus": 8
			},
			5: {
				"texture": preload("res://CharacterSprites/Armors/5/head.png"),
				"wave_required": 35,
				"vitality_bonus": 25,
				"defense_bonus": 10
			}
		}
	},
	"armor_body": {
		"name": "Chestplate",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Armors/1/armor.png"),
				"wave_required": 0,
				"vitality_bonus": 10,
				"defense_bonus": 3
			},
			2: {
				"texture": preload("res://CharacterSprites/Armors/2/armor.png"),
				"wave_required": 4,
				"vitality_bonus": 15,
				"defense_bonus": 5
			},
			3: {
				"texture": preload("res://CharacterSprites/Armors/3/armor.png"),
				"wave_required": 9,
				"vitality_bonus": 20,
				"defense_bonus": 7
			},
			4: {
				"texture": preload("res://CharacterSprites/Armors/4/armor.png"),
				"wave_required": 20,
				"vitality_bonus": 25,
				"defense_bonus": 9
			},
			5: {
				"texture": preload("res://CharacterSprites/Armors/5/armor.png"),
				"wave_required": 35,
				"vitality_bonus": 30,
				"defense_bonus": 11
			}
		}
	},
	"armor_gloves": {
		"name": "Gauntlets",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Armors/1/gloves.png"),
				"wave_required": 0,
				"vitality_bonus": 1,
				"defense_bonus": 1
			},
			2: {
				"texture": preload("res://CharacterSprites/Armors/2/gloves.png"),
				"wave_required": 4,
				"vitality_bonus":3,
				"defense_bonus": 2
			},
			3: {
				"texture": preload("res://CharacterSprites/Armors/3/gloves.png"),
				"wave_required": 9,
				"vitality_bonus": 6,
				"defense_bonus": 3
			},
			4: {
				"texture": preload("res://CharacterSprites/Armors/4/gloves.png"),
				"wave_required": 20,
				"vitality_bonus":9,
				"defense_bonus": 4
			},
			5: {
				"texture": preload("res://CharacterSprites/Armors/5/gloves.png"),
				"wave_required": 35,
				"vitality_bonus": 15,
				"defense_bonus": 5
			}
		}
	},
	"armor_boots": {
		"name": "Boots",
		"levels": {
			1: {
				"texture": preload("res://CharacterSprites/Armors/1/boots.png"),
				"wave_required": 0,
				"vitality_bonus": 1,
				"defense_bonus": 1
			},
			2: {
				"texture": preload("res://CharacterSprites/Armors/2/boots.png"),
				"wave_required": 4,
				"vitality_bonus": 8,
				"defense_bonus": 2
			},
			3: {
				"texture": preload("res://CharacterSprites/Armors/3/boots.png"),
				"wave_required": 9,
				"vitality_bonus": 12,
				"defense_bonus": 3
			},
			4: {
				"texture": preload("res://CharacterSprites/Armors/4/boots.png"),
				"wave_required": 20,
				"vitality_bonus": 16,
				"defense_bonus": 4
			},
			5: {
				"texture": preload("res://CharacterSprites/Armors/5/boots.png"),
				"wave_required": 35,
				"vitality_bonus": 20,
				"defense_bonus": 5
			}
		}
	}
	# Você pode estender adicionando “armor_belt”, “armor_shield” etc.
}

func get_weapon_level_data(weapon_id: String, level: int) -> Dictionary:
	if not weapons.has(weapon_id):
		return {}
	
	var wpn = weapons[weapon_id]
	if not wpn["levels"].has(level):
		return {}
	
	return wpn["levels"][level]
func get_armor_level_data(armor_id: String, level: int) -> Dictionary:
	if not armors.has(armor_id):
		return {}
	var arm = armors[armor_id]
	if not arm["levels"].has(level):
		return {}
	return arm["levels"][level]
