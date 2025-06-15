extends Node

var itens: Dictionary = {
	"item_1": {
		"nome": "Fúria Afiada",
		"icone": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 85.png",
		"preco": 500,
		"descricao": "Adiciona 10 de força, aumentando o dano físico",
		"efeitos": {
			"forca": 10
		}
	},
	"item_2": {
		"nome": "Sede de Sangue",
		"icone": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 93.png",
		"preco": 1500,
		"descricao": "Ganha 10% de roubo de vida baseado no dano",
		"efeitos": {
			"roubo_vida": 10
		}
	},
	"item_3": {
		"nome": "Passo do Relâmpago",
		"icone": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 80.png",
		"preco": 2000,
		"descricao": "Adiciona 10 de agilidade, aumentando a velocidade de movimento",
		"efeitos": {
			"agilidade": 10
		}
	},
	"item_4": {
		"nome": "Bastião Inquebrável",
		"icone": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 76.png",
		"preco": 2000,
		"descricao": "Ganha 15 de defesa contra dano físico",
		"efeitos": {
			"vitalidade": 15
		}
	}
}

func obter_dados_item(id_item: String) -> Dictionary:
	if itens.has(id_item):
		return itens[id_item]
	return {}
