extends CanvasLayer

signal menu_closed      # Sinal emitido quando o menu é fechado
signal start_wave       # Sinal emitido quando o jogador clica em "Start Wave"

@onready var main_menu: Control = $Container/Buttons
@onready var weapons_list: Control = $Container/Weapons

func _ready() -> void:
	# Conecta sinais dos botões do menu principal
	if $Container/Buttons/StartWave:
		$Container/Buttons/StartWave.connect("pressed", Callable(self, "_on_start_wave_pressed"))
	else:
		print("Erro: Botão StartWave não encontrado!")

	if $Container/Buttons/weaponsOption:
		$Container/Buttons/weaponsOption.connect("pressed", Callable(self, "_on_weapons_pressed"))
	else:
		print("Erro: Botão WeaponsButton não encontrado!")

	# Conecta o botão "Back" do painel de armas
	if $Container/Weapons/BackButton:
		$Container/Weapons/BackButton.connect("pressed", Callable(self, "_on_back_to_main_menu_pressed"))
	else:
		print("Erro: Botão BackButton não encontrado!")

	# Conecta o botão "Sword" (ajuste o nome conforme seu nó) 
	# para chamar o método que equipa a espada/escudo no Player
	if $Container/Weapons/SwordButton:
		$Container/Weapons/SwordButton.connect("pressed", Callable(self, "_on_sword_pressed"))
	else:
		print("Erro: Botão SwordButton não encontrado!")

func _on_start_wave_pressed() -> void:
	emit_signal("start_wave")
	print("Início da próxima wave solicitado!")
	on_close_button_pressed()  # Fecha o menu

func on_close_button_pressed() -> void:
	# Fecha completamente o menu
	emit_signal("menu_closed")

func _on_weapons_pressed() -> void:
	# Mostra a lista de armas, oculta o menu principal
	main_menu.visible = false
	weapons_list.visible = true

func _on_back_to_main_menu_pressed() -> void:
	# Volta para o menu principal
	main_menu.visible = true
	weapons_list.visible = false

func _on_sword_pressed() -> void:
	# Quando o jogador clica no botão de “Espada” no menu,
	# acessamos o Player e chamamos um método para equipar espada/escudo
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.equip_sword_and_shield()
	else:
		print("Player não encontrado na cena atual!")
