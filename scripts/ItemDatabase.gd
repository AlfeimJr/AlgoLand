extends Node

var items: Dictionary = {
	"item_1": {
		"name": "Sharp Fury",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 85.png",
		"price": 1000,
		"description": "Add 10 strength, increasing physical damage",
		"effects": {
			"strength": 10
		}
	},
	"item_2": {
		"name": "Bloodlust",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 93.png",
		"price": 3000,
		"description": "Gain 10% lifesteal based on damage",
		"effects": {
			"lifesteal": 10
		}
	},
	"item_3": {
		"name": "Lightning Step",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 80.png",
		"price": 4000,
		"description": "Add 10 agility, increasing movement speed",
		"effects": {
			"agility": 10
		}
	},
	"item_4": {
		"name": "Unbreakable Bastion",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 76.png",
		"price": 2000,
		"description": "Gain 15 defense against physical damage",
		"effects": {
			"vitality": 15
		}
	}
}

func get_item_data(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}
