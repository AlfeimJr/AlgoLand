extends Node

var armas = {
	# ==========================
	# 1) ARMAS JA EXISTENTES
	# ==========================

	"espada_basica": {
		"nome": "Espada Básica",
		"niveis": {
			1: {
				"textura": preload("res://CharacterSprites/Arms/swords/Sword_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/swords/Attack/slash_1.png"),
				"onda_necessaria": 0,
				"bonus_forca": 5,
				"dano": 10  
			},
			2: {
				"textura": preload("res://CharacterSprites/Arms/swords/swords_upgraded/2/Sword_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/2/slash_1.png"),
				"onda_necessaria": 4,
				"bonus_forca": 10,
				"dano": 20
			},
			3: {
				"textura": preload("res://CharacterSprites/Arms/swords/swords_upgraded/3/Sword_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/3/slash_1.png"),
				"onda_necessaria": 9,
				"bonus_forca": 15,
				"dano": 30
			},
			4: {
				"textura": preload("res://CharacterSprites/Arms/swords/swords_upgraded/4/Sword_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/4/slash_1.png"),
				"onda_necessaria": 20,
				"bonus_forca": 20,
				"dano": 40
			},
			5: {
				"textura": preload("res://CharacterSprites/Arms/swords/swords_upgraded/5/Sword_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/5/slash_1.png"),
				"onda_necessaria": 35,
				"bonus_forca": 25,
				"dano": 50
			}
		}
	},

	"escudo_basico": {
		"nome": "Escudo Básico",
		"niveis": {
			1: {
				"textura": preload("res://CharacterSprites/Arms/shields/shield_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/shields/attack/slash_1.png"),
				"onda_necessaria": 0,
				"bonus_vitalidade": 2,
				"bonus_defesa": 1
			},
			2: {
				"textura": preload("res://CharacterSprites/Arms/shields/shields_upgraded/2/shield_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/2/slash_1.png"),
				"onda_necessaria": 4,
				"bonus_vitalidade": 5,
				"bonus_defesa": 2
			},
			3: {
				"textura": preload("res://CharacterSprites/Arms/shields/shields_upgraded/3/shield_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/3/slash_1.png"),
				"onda_necessaria": 9,
				"bonus_vitalidade": 10,
				"bonus_defesa": 4
			},
			4: {
				"textura": preload("res://CharacterSprites/Arms/shields/shields_upgraded/4/shield_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/4/slash_1.png"),
				"onda_necessaria": 20,
				"bonus_vitalidade": 12,
				"bonus_defesa": 6
			},
			5: {
				"textura": preload("res://CharacterSprites/Arms/shields/shields_upgraded/5/shield_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/shields/attack/shields_upgraded/slash_1/5/slash_1.png"),
				"onda_necessaria": 35,
				"bonus_vitalidade": 15,
				"bonus_defesa": 8
			}
		}
	},

	"lanca_basica": {
		"nome": "Lança Básica",
		"niveis": {
			1: {
				"textura": preload("res://CharacterSprites/Arms/spears/spear_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/spears/Attack/slash_1.png"),
				"onda_necessaria": 0,
				"bonus_forca": 15,
				"dano": 30  
			},
			2: {
				"textura": preload("res://CharacterSprites/Arms/spears/spears_upgraded/2/spear_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/2/slash_1.png"),
				"onda_necessaria": 4,
				"bonus_forca": 20,
				"dano": 40  
			},
			3: {
				"textura": preload("res://CharacterSprites/Arms/spears/spears_upgraded/3/spear_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/3/slash_1.png"),
				"onda_necessaria": 9,
				"bonus_forca": 25,
				"dano": 50  
			},
			4: {
				"textura": preload("res://CharacterSprites/Arms/spears/spears_upgraded/4/spear_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/4/slash_1.png"),
				"onda_necessaria": 20,
				"bonus_forca": 30,
				"dano": 60  
			},
			5: {
				"textura": preload("res://CharacterSprites/Arms/spears/spears_upgraded/5/spear_1.png"),
				"textura_ataque": preload("res://CharacterSprites/Arms/spears/Attack/spears_upgraded/slash_1/5/slash_1.png"),
				"onda_necessaria": 35,
				"bonus_forca": 35,
				"dano": 65  
			}
		}
	}
}

var armaduras = {
	"armadura_cabeca": {
		"nome": "Elmo",
		"niveis": {
			1: {
				"textura": preload("res://CharacterSprites/Armors/1/head.png"),
				"onda_necessaria": 0,
				"bonus_vitalidade": 5,
				"bonus_defesa": 2
			},
			2: {
				"textura": preload("res://CharacterSprites/Armors/2/head.png"),
				"onda_necessaria": 4,
				"bonus_vitalidade": 10,
				"bonus_defesa": 4
			},
			3: {
				"textura": preload("res://CharacterSprites/Armors/3/head.png"),
				"onda_necessaria": 9,
				"bonus_vitalidade": 15,
				"bonus_defesa": 6
			},
			4: {
				"textura": preload("res://CharacterSprites/Armors/4/head.png"),
				"onda_necessaria": 20,
				"bonus_vitalidade": 20,
				"bonus_defesa": 8
			},
			5: {
				"textura": preload("res://CharacterSprites/Armors/5/head.png"),
				"onda_necessaria": 35,
				"bonus_vitalidade": 25,
				"bonus_defesa": 10
			}
		}
	},
	"armadura_corpo": {
		"nome": "Peitoral",
		"niveis": {
			1: {
				"textura": preload("res://CharacterSprites/Armors/1/armor.png"),
				"onda_necessaria": 0,
				"bonus_vitalidade": 10,
				"bonus_defesa": 3
			},
			2: {
				"textura": preload("res://CharacterSprites/Armors/2/armor.png"),
				"onda_necessaria": 4,
				"bonus_vitalidade": 15,
				"bonus_defesa": 5
			},
			3: {
				"textura": preload("res://CharacterSprites/Armors/3/armor.png"),
				"onda_necessaria": 9,
				"bonus_vitalidade": 20,
				"bonus_defesa": 7
			},
			4: {
				"textura": preload("res://CharacterSprites/Armors/4/armor.png"),
				"onda_necessaria": 20,
				"bonus_vitalidade": 25,
				"bonus_defesa": 9
			},
			5: {
				"textura": preload("res://CharacterSprites/Armors/5/armor.png"),
				"onda_necessaria": 35,
				"bonus_vitalidade": 30,
				"bonus_defesa": 11
			}
		}
	},
	"armadura_luvas": {
		"nome": "Manoplas",
		"niveis": {
			1: {
				"textura": preload("res://CharacterSprites/Armors/1/gloves.png"),
				"onda_necessaria": 0,
				"bonus_vitalidade": 1,
				"bonus_defesa": 1
			},
			2: {
				"textura": preload("res://CharacterSprites/Armors/2/gloves.png"),
				"onda_necessaria": 4,
				"bonus_vitalidade": 3,
				"bonus_defesa": 2
			},
			3: {
				"textura": preload("res://CharacterSprites/Armors/3/gloves.png"),
				"onda_necessaria": 9,
				"bonus_vitalidade": 6,
				"bonus_defesa": 3
			},
			4: {
				"textura": preload("res://CharacterSprites/Armors/4/gloves.png"),
				"onda_necessaria": 20,
				"bonus_vitalidade": 9,
				"bonus_defesa": 4
			},
			5: {
				"textura": preload("res://CharacterSprites/Armors/5/gloves.png"),
				"onda_necessaria": 35,
				"bonus_vitalidade": 15,
				"bonus_defesa": 5
			}
		}
	},
	"armadura_botas": {
		"nome": "Botas",
		"niveis": {
			1: {
				"textura": preload("res://CharacterSprites/Armors/1/boots.png"),
				"onda_necessaria": 0,
				"bonus_vitalidade": 1,
				"bonus_defesa": 1
			},
			2: {
				"textura": preload("res://CharacterSprites/Armors/2/boots.png"),
				"onda_necessaria": 4,
				"bonus_vitalidade": 8,
				"bonus_defesa": 2
			},
			3: {
				"textura": preload("res://CharacterSprites/Armors/3/boots.png"),
				"onda_necessaria": 9,
				"bonus_vitalidade": 12,
				"bonus_defesa": 3
			},
			4: {
				"textura": preload("res://CharacterSprites/Armors/4/boots.png"),
				"onda_necessaria": 20,
				"bonus_vitalidade": 16,
				"bonus_defesa": 4
			},
			5: {
				"textura": preload("res://CharacterSprites/Armors/5/boots.png"),
				"onda_necessaria": 35,
				"bonus_vitalidade": 20,
				"bonus_defesa": 5
			}
		}
	}
}

func obter_dados_nivel_arma(id_arma: String, nivel: int) -> Dictionary:
	if not armas.has(id_arma):
		return {}
	
	var arma = armas[id_arma]
	if not arma["niveis"].has(nivel):
		return {}
	
	return arma["niveis"][nivel]

func obter_dados_nivel_armadura(id_armadura: String, nivel: int) -> Dictionary:
	if not armaduras.has(id_armadura):
		return {}
	var armadura = armaduras[id_armadura]
	if not armadura["niveis"].has(nivel):
		return {}
	return armadura["niveis"][nivel]
