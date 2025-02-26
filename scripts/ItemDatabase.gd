# ItemDatabase.gd
extends Node

var items: Dictionary = {
	"item_1": {
		"name": "Fúria Afiada",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 85.png",
		"price": "1000"
	},
	"item_2": {
		"name": "Sede de Sangue",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 93.png",
		"price": "1000"
	},
	"item_3": {
		"name": "Passo Relâmpago",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 80.png",
		"price": "1000"
	},
	"item_4": {
		"name": "Bastião Inquebrável",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 76.png",
		"price": "1000"
	}
}

func get_item_data(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}
