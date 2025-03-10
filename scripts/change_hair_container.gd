extends Node2D

@onready var player = $"../Player"

# Botões para trocar o tipo de cabelo/roupa
@onready var btn_next_hair = $Container/ChangeHairContainer/ChangeHair
@onready var btn_prev_hair = $Container/ChangeHairContainer/ChangeHairBack
@onready var btn_next_outfit = $Container/ChangeOutfitContainer/ChangeOutfit
@onready var btn_prev_outfit = $Container/ChangeOutfitContainer/ChangeOutfitBack
@onready var btn_save = $Container/Save/Button

# Campo de texto para nickname
@onready var line_edit = $Container/NickName/LineEdit

# Sliders para cor do cabelo (RGB)
@onready var red_slider = $HairColor/HairColorContainer/RedSlider
@onready var green_slider = $HairColor/HairColorContainer2/GreenSlider
@onready var blue_slider = $HairColor/HairColorContainer3/BlueSlider

# Labels que exibem o valor atual dos sliders
@onready var red_label = $HairColor/HairColorContainer/RedValueLabel
@onready var green_label = $HairColor/HairColorContainer2/GreenValueLabel
@onready var blue_label = $HairColor/HairColorContainer3/BlueValueLabel

var hair_color: Color = Color(1, 1, 1, 1)  # RGBA
var nickname: String = ""

func _ready() -> void:
	if player:
		# Conecta botões de trocar cabelo/roupa ao Player
		btn_next_hair.connect("pressed", player._on_change_hair_pressed)
		btn_prev_hair.connect("pressed", player._on_change_hair_back_pressed)
		btn_next_outfit.connect("pressed", player._on_change_outfit_pressed)
		btn_prev_outfit.connect("pressed", player._on_change_outfit_back_pressed)
		
		# Botão de salvar customização
		btn_save.connect("pressed", Callable(self, "_on_save_pressed"))

		# LineEdit para nickname
		line_edit.connect("text_changed", Callable(self, "_on_line_edit_text_changed"))

		# Configura sliders (0 a 255) para R, G, B
		red_slider.min_value = 0
		red_slider.max_value = 255
		green_slider.min_value = 0
		green_slider.max_value = 255
		blue_slider.min_value = 0
		blue_slider.max_value = 255

		# Conecta sinais dos sliders
		red_slider.connect("value_changed", Callable(self, "_on_red_slider_changed"))
		green_slider.connect("value_changed", Callable(self, "_on_green_slider_changed"))
		blue_slider.connect("value_changed", Callable(self, "_on_blue_slider_changed"))

		# Define uma cor inicial (ex.: loiro)
		red_slider.value = 255
		green_slider.value = 220
		blue_slider.value = 100
		_update_hair_color()

		# Conecta o sinal do player (quando finaliza customização)
		player.connect("customization_finished", Callable(self, "_on_player_customization_finished"))
	else:
		print("Erro: Player não encontrado!")

func _on_line_edit_text_changed(new_text: String) -> void:
	player.nickname = new_text

# Sliders de cor
func _on_red_slider_changed(value: float) -> void:
	red_label.text = str(value)
	_update_hair_color()

func _on_green_slider_changed(value: float) -> void:
	green_label.text = str(value)
	_update_hair_color()

func _on_blue_slider_changed(value: float) -> void:
	blue_label.text = str(value)
	_update_hair_color()

# Atualiza hair_color e aplica no sprite do player
func _update_hair_color() -> void:
	var r = int(red_slider.value)
	var g = int(green_slider.value)
	var b = int(blue_slider.value)
	hair_color = Color(r / 255.0, g / 255.0, b / 255.0, 1.0)

	if player and player.has_method("set_hair_color"):
		player.set_hair_color(hair_color)
	else:
		var hair_sprite = player.get_node("CompositeSprites/BaseSprites/Hair")
		if hair_sprite:
			hair_sprite.modulate = hair_color

# Botão "Save" pressionado
func _on_save_pressed() -> void:
	# Chama a função do player que emite o sinal customization_finished
	player.save_customization()

# Recebe o sinal do Player e salva no JSON
func _on_player_customization_finished(hair_index: int, outfit_index: int, nickname: String, color: Color) -> void:
	print("Personalização concluída! Cabelo:", hair_index, "Roupa:", outfit_index, "Cor:", color)
	save_to_json(hair_index, outfit_index, nickname, color)

func save_to_json(hair_index: int, outfit_index: int, nickname: String, chosen_color: Color) -> void:
	var documents_dir = OS.get_user_data_dir()
	var file_path = documents_dir.path_join("player_config.json")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Erro ao abrir o arquivo para escrita.")
		return
	
	# Converte a cor para string (ex.: "#FFDC64")
	var color_string = chosen_color.to_html()

	var data = {
		"curr_hair": hair_index,
		"curr_outfit": outfit_index,
		"nickname": nickname,
		"hair_color": color_string
	}
	var json = JSON.new()
	var json_string = json.stringify(data)
	file.store_string(json_string)
	file.close()

	# Carrega a cena principal
	var scene = load("res://cenas/cenario.tscn")
	var instance = scene.instantiate()
	get_tree().root.add_child(instance)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = instance
