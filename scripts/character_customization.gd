extends Node2D

@onready var player_custom = $PlayerCustomization # O novo node com script "PlayerCustomization.gd"

func _ready() -> void:
	# Conecta o sinal do player_custom
	player_custom.connect("customization_finished", Callable(self, "_on_player_customization_finished"))

func _on_player_customization_finished(hair, outfit, color, nickname):
	# Aqui você faz a lógica de salvamento em JSON (ou delega ao player_custom).
	# Em seguida, carrega a cena principal do jogo.
	print("Personalização concluída! Cabelo:", hair, "Roupa:", outfit, "Cor:", color, "Nick:", nickname)

	# Salvar em JSON:
	var hair_color_data = {
		"r": color.r,
		"g": color.g,
		"b": color.b,
		"a": color.a
	}
	var data = {
		"curr_hair": hair,
		"curr_outfit": outfit,
		"nickname": nickname,
		"hair_color": hair_color_data
	}

	var documents_dir = OS.get_user_data_dir()
	var file_path = documents_dir.path_join("player_config.json")

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Erro ao abrir o arquivo para escrita.")
		return

	var json = JSON.new()
	var json_string = json.stringify(data)
	file.store_string(json_string)
	file.close()

	# Transição para a cena principal utilizando change_scene_to_file (Godot 4)
	get_tree().change_scene_to_file("res://cenas/cenario.tscn")
