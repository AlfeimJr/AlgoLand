extends Node

var coins: int = 1000

func _ready() -> void:
	# Atualiza a UI de moedas (caso já exista)
	update_coins_ui()

func add_coins(amount: int) -> void:
	coins += amount
	update_coins_ui()

func spend_coins(amount: int) -> bool:
	# Retorna true/false se a compra foi possível
	if coins >= amount:
		coins -= amount
		update_coins_ui()
		return true
	return false

func reset_coins() -> void:
	coins = 1000
	update_coins_ui()

func update_coins_ui() -> void:
	# Se você tem um Label em /root/cenario/UI/Coins/count
	# e quer atualizar seu texto:
	var label = get_tree().get_root().get_node_or_null("cenario/UI/Coins/count")
	if label and label is Label:
		label.text = str(coins)
