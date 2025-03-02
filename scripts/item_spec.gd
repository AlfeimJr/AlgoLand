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
		print("Player não encontrado!")
		return

	var price = current_item_data.get("price", 0)
	if player.coins >= price:
		player.spend_coins(price)
		var coins_label = coins.get_node("count") as Label
		coins_label.text = str(player.coins)
		# Aqui vem a lógica de aplicar as propriedades ao Player
		# Se o item tiver 'defense', soma na defesa do Player
		if current_item_data.has("defense"):
			player._defense += current_item_data["defense"]
			print("Defesa do Player agora é: ", player._defense)

		# Se tiver 'damage', soma no ataque
		if current_item_data.has("damage"):
			player._attack_damage += current_item_data["damage"]
			print("Dano do Player agora é: ", player._attack_damage)

		# Se tiver 'max_hp', aumenta a vida máxima
		if current_item_data.has("max_hp"):
			player.max_hp += current_item_data["max_hp"]
			player.current_hp += current_item_data["max_hp"]  # se quiser também curar
			player.update_hp_bar()
			print("HP máximo do Player agora é: ", player.max_hp)

		
	else:
		print("Moedas insuficientes para comprar este item!")
