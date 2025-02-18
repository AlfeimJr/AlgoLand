extends Node2D

@onready var player = $"../Player"
@onready var btn_next_hair =$Container/ChangeHairContainer/ChangeHair
@onready var btn_prev_hair =$Container/ChangeHairContainer/ChangeHairBack
@onready var btn_next_outfit = $Container/ChangeOutfitContainer/ChangeOutfit
@onready var btn_prev_outfit = $Container/ChangeOutfitContainer/ChangeOutfitBack
@onready var btn_save = $Container/Save/Button
@onready var line_edit = $Container/NickName/LineEdit

var nickname: String = ""
func _ready():
	if player:
		btn_next_hair.connect("pressed", player._on_change_hair_pressed)
		btn_prev_hair.connect("pressed", player._on_change_hair_back_pressed)
		btn_next_outfit.connect("pressed", player._on_change_outfit_pressed)
		btn_prev_outfit.connect("pressed", player._on_change_outfit_back_pressed)
		btn_save.connect("pressed", player.save_customization)
	else:
		print("Erro: Player não encontrado!")


func _on_line_edit_text_changed(new_text: String) -> void:
	player.nickname = new_text
