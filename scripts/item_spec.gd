extends Panel

var current_item_data: Dictionary
@onready var coins = $"../Coins"

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func set_item_data(data: Dictionary) -> void:
	current_item_data = data
	$ItemName.text = data["name"]
	$ItemPrice.text = str(data["price"])
	$ItemSelected/itemImage.texture = load(data["icon"])
	$ItemDescription.text = data["description"]

func _on_button_pressed() -> void:
	var player = get_tree().get_root().get_node("cenario/Player")
	if not player:
		return

	var price = current_item_data.get("price", 0)
	if GameData.coins >= price:
		player.spend_coins(price)
		var coins_label = coins.get_node("count") as Label
		coins_label.text = str(GameData.coins)
		if current_item_data.has("effects"):
			var effects = current_item_data["effects"]
			for key in effects.keys():
				var value = effects[key]
				match key:
					"strength":
						player.stats.strength += value
					"vitality":
						player.stats.vitality += value
					"max_hp":
						player.stats.max_hp += value
						player.current_hp += value
					"agility":        # Adicione esse branch para aumentar a agilidade
						player.stats.agility += value
					_:
						pass
			player.stats.calculate_derived_stats()
			player.current_hp = player.stats.max_hp
			player.update_hp_bar()
			if player.using_sword:
				player.stats.move_speed += 50
		player.purchased_items.append(current_item_data)
	else:
		pass
