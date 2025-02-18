extends CanvasLayer

signal menu_closed  # Sinal emitido quando o menu é fechado
signal start_wave   # Sinal emitido quando o jogador clica em "Start Wave"

@onready var main_menu: Control = $Container/Buttons  # Painel com os botões principais ("Start Wave" e "Weapons")
@onready var weapons_list: Control = $Container/Weapons  # Control com a lista de armas

func _ready() -> void:
	# Conecta os sinais dos botões principais
	if $Container/Buttons/StartWave != null:
		$Container/Buttons/StartWave.connect("pressed", Callable(self, "_on_start_wave_pressed"))
	else:
		print("Erro: Botão StartWave não encontrado!")

	if $Container/Buttons/weaponsOption != null:
		$Container/Buttons/weaponsOption.connect("pressed", Callable(self, "_on_weapons_pressed"))
	else:
		print("Erro: Botão WeaponsButton não encontrado!")

	# Conecta o botão "Back" do painel de armas
	if $Container/Weapons/BackButton != null:
		$Container/Weapons/BackButton.connect("pressed", Callable(self, "_on_back_to_main_menu_pressed"))
	else:
		print("Erro: Botão BackButton não encontrado!")

func _on_start_wave_pressed() -> void:
	# Emite o sinal para iniciar a próxima wave
	emit_signal("start_wave")
	print("Início da próxima wave solicitado!")
	on_close_button_pressed()  # Fecha o menu após iniciar a wave

func on_close_button_pressed() -> void:
	# Fecha o menu completamente
	emit_signal("menu_closed")

func _on_weapons_pressed() -> void:
	# Oculta o menu principal e mostra o painel de armas
	main_menu.visible = false
	weapons_list.visible = true

func _on_back_to_main_menu_pressed() -> void:
	# Volta ao menu principal (oculta o painel de armas e mostra o menu principal)
	main_menu.visible = true
	weapons_list.visible = false
