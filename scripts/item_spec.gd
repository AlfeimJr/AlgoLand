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
	if player.coins >= price:
		player.spend_coins(price)
		var coins_label = coins.get_node("count") as Label
		coins_label.text = str(player.coins)
		
		# Se o item possui a chave "effects", aplica cada efeito
		if current_item_data.has("effects"):
			var effects = current_item_data["effects"]
			for key in effects.keys():
				var value = effects[key]
				match key:
					"strength":
						player.stats.strength += value
						print("Força do Player agora é: ", player.stats.strength)
					"defense":
						player.stats.defense += value
						print("Defesa do Player agora é: ", player.stats.defense)
					"max_hp":
						player.stats.max_hp += value
						player.current_hp += value  # Se quiser curar também
						player.update_hp_bar()
						print("HP máximo do Player agora é: ", player.stats.max_hp)
					_:
						print("Efeito desconhecido: ", key)
			# Recalcula os atributos derivados (como attack_damage)
			player.stats.calculate_derived_stats()
			if player.using_sword:
				player.stats.move_speed += 50
		# Adiciona o item comprado à lista de itens adquiridos
		player.purchased_items.append(current_item_data)
	else:
		print("Moedas insuficientes para comprar este item!")
