# ItemDatabase.gd
extends Node

var items: Dictionary = {
	"item_1": {
		"name": "Sharp Fury",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 85.png",
		"price": 1000,
		"description": "Add 10 physical damage",
		"damage": 10
	},
	"item_2": {
		"name": "Bloodlust",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 93.png",
		"price": 1000,
		"description": "Gain 10% lifesteal based on damage",
		"lifesteal": 10
	},
	"item_3": {
		"name": "Lightning Step",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 80.png",
		"price": 1000,
		"description": "Add 10 movement speed",
		"movespeed": 10
	},
	"item_4": {
		"name": "Unbreakable Bastion",
		"icon": "res://UI/craftpix-net-629015-100-skill-icons-pack-for-rpg/PNG/skill icon 76.png",
		"price": 1000,
		"description": "Gain 15 defense against physical damage",
		"defense": 15
	}
}

func get_item_data(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}
