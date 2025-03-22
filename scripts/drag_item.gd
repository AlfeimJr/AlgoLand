extends TextureRect

func _get_drag_data(at_position):
	# Criar um Control vazio como container principal
	var drag_container = Control.new()
	
	# Criar o elemento visual do preview
	var preview_texture = TextureRect.new()
	preview_texture.texture = texture
	preview_texture.expand = true
	preview_texture.size = Vector2(15, 15)
	
	# Adicionar o elemento visual como filho do container
	drag_container.add_child(preview_texture)
	
	# Posicionar o elemento visual com offset negativo para centralizá-lo
	preview_texture.position = -preview_texture.size / 2
	
	# Usar o container como preview
	set_drag_preview(drag_container)
	
	return texture
	
func _can_drop_data(_pos, data):
	return data is Texture2D
	
func _drop_data(_pos, data):
	texture = data
