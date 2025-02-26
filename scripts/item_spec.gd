extends Panel

var current_item_data: Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_item_data(data: Dictionary) -> void:
	current_item_data = data
	# Aqui você atualiza o design do painel com as infos do item
	# Exemplo, se tiver um Label ou TextureRect:
	$ItemName.text = data["name"]
	$ItemPrice.text = data["price"]
	$ItemSelected/itemImage.texture = load(data["icon"])
